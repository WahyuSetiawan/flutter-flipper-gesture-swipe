import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

typedef Widget IndexedItemBuilder(BuildContext, int);

enum FlipDirection { up, down }

class FlipPanel<T> extends StatefulWidget {
  final IndexedItemBuilder indexedItemBuilder;
  final Stream<T> itemStream;
  final int startIndex;
  final T initValue;
  final double height;
  final List<String> items;

  FlipPanel(
      {this.indexedItemBuilder,
      this.itemStream,
      this.startIndex,
      this.height,
      this.items,
      this.initValue});

  FlipPanel.builder(
      {@required IndexedItemBuilder itemBuilder,
      this.startIndex,
      this.height,
      this.items})
      : assert(items.length > 2),
        itemStream = null,
        indexedItemBuilder = itemBuilder,
        initValue = null;

  @override
  State<StatefulWidget> createState() {
    return FlipPanelState();
  }
}

class FlipPanelState<T> extends State<FlipPanel> with TickerProviderStateMixin {
  AnimationController _controller;
  Animation _animation;
  int _currentIndex;
  bool _running;
  bool _dragging;

  final _perspective = 0.001;
  final _zeroAngle = 0.001;

  double _height;

  double angleChange = 0.0001;
  double _startDrag = 0.0;
  double _matrixXfromBelow = 0.0;

  FlipDirection _flipDirection = null;

  Widget _upperChild;
  Widget _lowerChild;

  Widget _upperPrevious, _upperNext;
  Widget _lowerPrevious, _lowerNext;
  Widget _containerOpacityStart, _containerOpacityEnd;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _currentIndex = 0;
    _running = false;
    _height = widget.height;
  }

  @override
  Widget build(BuildContext context) {
    _buildChildWidgetsIfNeed(context);

    return Container(
      child: _buildPanel(),
    );
  }

  _buildChildWidgetsIfNeed(BuildContext context) {
    Widget makeUpperClip(Widget widget) {
      return ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.5,
          child: widget,
        ),
      );
    }

    Widget makeLowerClip(Widget widget) {
      return ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 0.5,
          child: widget,
        ),
      );
    }

    _upperChild =
        makeUpperClip(widget.indexedItemBuilder(context, _currentIndex));
    _lowerChild =
        makeLowerClip(widget.indexedItemBuilder(context, _currentIndex));

    if (_currentIndex + 1 < widget.items.length) {
      _upperNext =
          makeUpperClip(widget.indexedItemBuilder(context, _currentIndex + 1));
      _lowerNext =
          makeLowerClip(widget.indexedItemBuilder(context, _currentIndex + 1));
    } else {
      _upperNext = makeUpperClip(widget.indexedItemBuilder(context, 0));
      _lowerNext = makeLowerClip(widget.indexedItemBuilder(context, 0));
    }

    if (_currentIndex - 1 >= 0) {
      _upperPrevious =
          makeUpperClip(widget.indexedItemBuilder(context, _currentIndex - 1));
      _lowerPrevious =
          makeLowerClip(widget.indexedItemBuilder(context, _currentIndex - 1));
    } else {
      _upperPrevious = makeUpperClip(
          widget.indexedItemBuilder(context, widget.items.length - 1));
      _lowerPrevious = makeLowerClip(
          widget.indexedItemBuilder(context, widget.items.length - 1));
    }

    double _areaOpacity = math.pi / 4;
    double _maxOpacity = 0.9;

    _containerOpacityStart = Positioned(
      top: 0,
      right: 0,
      left: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.black.withOpacity((angleChange < _areaOpacity)
                ? (math.pow((angleChange / _areaOpacity), 2) >= 1)
                    ? _maxOpacity
                    : (_maxOpacity -
                        (math.pow((angleChange / _areaOpacity), 2) *
                            _maxOpacity))
                : 0.0)),
      ),
    );

    print(((math.pow(
                ((angleChange - (math.pi - _areaOpacity)) / _areaOpacity), 2) /
            _areaOpacity) *
        _maxOpacity));

    _containerOpacityEnd = Positioned(
      top: 0,
      right: 0,
      left: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.black.withOpacity((angleChange >
                    (math.pi - _areaOpacity))
                ? ((((math.pow(
                                    ((angleChange - (math.pi - _areaOpacity)) /
                                        _areaOpacity),
                                    2) /
                                _areaOpacity) *
                            _maxOpacity) <
                        1.0))
                    ? ((math.pow(
                                ((angleChange - (math.pi - _areaOpacity)) /
                                    _areaOpacity),
                                2) /
                            _areaOpacity) *
                        _maxOpacity)
                    : _maxOpacity
                : 0.0)),
      ),
    );
  }

  Widget _buildUpperFlipPanel() {
    return (_flipDirection == FlipDirection.up)
        ? Stack(
            children: <Widget>[
              Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _upperChild,
              ),
              _containerOpacityEnd,
              Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(2, 2, 0.001)
                  ..rotateX(
                      ((math.pi / 2) < angleChange && angleChange < math.pi)
                          ? ((math.pi / 2) - (angleChange - (math.pi / 2)))
                          : math.pi / 2),
                child: _upperNext,
              ),
            ],
          )
        : Stack(
            children: <Widget>[
              Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _upperPrevious,
              ),
              _containerOpacityStart,
              Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(2, 2, 0.001)
                  ..rotateX(
                      (angleChange < math.pi / 2) ? angleChange : math.pi / 2),
                child: _upperChild,
              ),
            ],
          );
  }

  Widget _buildLowerFlipPanell() {
    return (_flipDirection == FlipDirection.up)
        ? Stack(
            children: <Widget>[
              Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(2, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _lowerNext,
              ),
              _containerOpacityStart,
              Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(2, 2, _perspective)
                  ..rotateX(
                      (angleChange < math.pi / 2) ? -angleChange : math.pi / 2),
                child: _lowerChild,
              ),
            ],
          )
        : Stack(
            children: <Widget>[
              Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(2, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _lowerChild,
              ),
              _containerOpacityEnd,
              Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(2, 2, _perspective)
                  ..rotateX(
                      ((math.pi / 2) < angleChange && angleChange < math.pi)
                          ? ((math.pi / 2) - (angleChange - (math.pi / 2))) * -1
                          : math.pi / 2),
                child: _lowerPrevious,
              ),
            ],
          );
  }

  Widget _buildPanel() {
    Widget zeroActivity = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateX(_zeroAngle),
          child: _upperChild,
        ),
        Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateX(_zeroAngle),
          child: _lowerChild,
        ),
      ],
    );

    Widget mainView = _running
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildUpperFlipPanel(),
              _buildLowerFlipPanell(),
            ],
          )
        : zeroActivity;

    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: mainView,
    );
  }

  void _handleDragStart(DragStartDetails details) {
    _running = true;
    _dragging = true;
    _startDrag = details.globalPosition.dy;
    _flipDirection = null;

    _controller.stop();
  }

  void _handleDragEnd(DragEndDetails details) {
    _controller =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              if (angleChange > (math.pi / 2)) {
                setState(() {
                  int _currentIndextmp = _currentIndex;

                  if (_flipDirection.toString() ==
                      FlipDirection.down.toString()) {
                    _currentIndextmp = _currentIndextmp - 1;
                  } else {
                    _currentIndextmp = _currentIndextmp + 1;
                  }

                  if (_currentIndextmp >= widget.items.length) {
                    _currentIndextmp = 0;
                  }

                  if (_currentIndextmp < 0) {
                    _currentIndextmp = widget.items.length - 1;
                  }

                  _currentIndex = _currentIndextmp;
                });
              } else {}

              setState(() {
                angleChange = _zeroAngle;
                _running = false;
                _dragging = false;
                _startDrag = 0;
                _flipDirection = null;
              });
            }
          })
          ..addListener(() {
            setState(() {
              try {
                angleChange = _animation.value;
              } catch (e) {
                angleChange = _zeroAngle;
              }
            });
          });

    _animation = Tween(
            begin: angleChange, end: (angleChange > math.pi / 2) ? math.pi : 0)
        .animate(_controller);

    _controller.forward();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    double angleChangetmp = 0.0;

    setState(() {
      _running = true;
      if (_flipDirection == null && _startDrag != details.globalPosition.dy) {
        _flipDirection = (_startDrag > details.globalPosition.dy)
            ? FlipDirection.up
            : FlipDirection.down;
      }

      if (_flipDirection != null) {
        if (_flipDirection.toString() == FlipDirection.up.toString()) {
          _matrixXfromBelow = ((details.globalPosition.dy - _startDrag) < 0)
              ? (details.globalPosition.dy - _startDrag) * -1
              : 0;

          angleChangetmp = (_matrixXfromBelow / widget.height) * (math.pi * 2);
        } else {
          _matrixXfromBelow = ((details.globalPosition.dy - _startDrag) > 0)
              ? (details.globalPosition.dy - _startDrag)
              : 0;

          angleChangetmp = (_matrixXfromBelow / widget.height) * (math.pi * 2);
        }

        if (angleChangetmp < math.pi) {
          angleChange = angleChangetmp;
        }
      }
    });
  }
}
