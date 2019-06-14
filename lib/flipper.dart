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

class FlipPanelState<T> extends State<FlipPanel> {
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

    if (_currentIndex - 1 >= 1) {
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
              Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
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
              Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
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
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _lowerNext,
              ),
              Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
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
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _lowerChild,
              ),
              Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
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

    Widget mainView = true
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
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      if (angleChange > (math.pi / 2)) {
        if (_currentIndex + 1 >= widget.items.length &&
            _flipDirection == FlipDirection.up) {
          _currentIndex = 0;
        } else if (_currentIndex - 1 < 0 &&
            _flipDirection == FlipDirection.down) {
          _currentIndex = widget.items.length - 1;
        } else {
          _currentIndex = _currentIndex + 1;
        }
      } else {
        print("batal pindah");
      }

      angleChange = _zeroAngle;
      _running = false;
      _dragging = false;
      _startDrag = 0;
      _flipDirection = null;
    });
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

        print(_matrixXfromBelow);
      }
    });
  }
}
