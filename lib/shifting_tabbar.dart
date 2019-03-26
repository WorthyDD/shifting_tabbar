library shifting_tabbar;

import 'package:flutter/material.dart';

/// A widget that displays a horizontal row of tabs with some kind of shifting animation.
///
/// Typically created instead of [AppBar] and in conjunction with a [TabBarView].
///
/// If a [TabController] is not provided, then a [DefaultTabController] ancestor
/// must be provided instead. The tab controller's [TabController.length] must
/// equal the length of the [tabs] list.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [TabBarView], which displays page views that correspond to each tab.
class ShiftingTabBar extends StatefulWidget implements PreferredSizeWidget {
  /// Creates a shifting tab bar.
  ///
  /// The [tabs] argument must not be null and its length must match the [controller]'s
  /// [TabController.length].
  ///
  /// If a [TabController] is not provided, then there must be a
  /// [DefaultTabController] ancestor.
  ///
  /// The [color] argument is used as background of tab bar If a [color] is not provided
  /// then it will use ancestor [ThemeData.primaryColor] property as default
  /// background color.
  ///
  /// The [brightness] argument is used to determin whetever the color of text must light
  /// or dark. If it's not provided it will use [Color.computeLuminance] function and
  /// [color] argument or [ThemeData.primaryColor] as arguments to determin this property.
  const ShiftingTabBar({
    Key key,
    @required this.tabs,
    this.controller,
    this.color,
    this.brightness,
  })  : assert(tabs != null),
        super(key: key);

  /// Typically a list of two or more [ShifitngTab] widgets.
  ///
  /// The length of this list must match the [controller]'s [TabController.length].
  final List<ShiftingTab> tabs;

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController controller;

  /// The color of widget background
  ///
  /// If a [color] is not provided then it will use ancestor [ThemeData.primaryColor]
  /// property as default background color.
  final Color color;

  /// Describes the contrast of background color.
  ///
  /// If [Brightness] is not provided, then it will use [Color.computeLuminance] function and
  /// background color as arguments to determin this property.
  final Brightness brightness;

  @override
  _ShiftingTabBarState createState() => _ShiftingTabBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ShiftingTabBarState extends State<ShiftingTabBar> {
  TabController _controller;
  Color _color;
  Brightness _brightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _controller = widget.controller ?? DefaultTabController.of(context);
    _color = widget.color ?? Theme.of(context).primaryColor;
    _brightness = widget.brightness ?? Brightness.light;

    _controller.animation.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _color,
      child: SafeArea(
        top: true,
        child: Row(
          children: _buildTabWidgets(),
        ),
      ),
    );
  }

  List<_ShiftingTabWidget> _buildTabWidgets() {
    final double margin =
        (MediaQuery.of(context).size.width / (widget.tabs.length + 1) - 19) / 2;
    final List<_ShiftingTabWidget> tabWidgets =
        List<Widget>(widget.tabs.length);

    for (int i = 0; i < widget.tabs.length; i++) {
      tabWidgets[i] = _ShiftingTabWidget(
        key: widget.tabs[i].key,
        animation: _ShiftingAnimation(_controller, i),
        margin: margin,
        icon: widget.tabs[i].icon,
        onTap: () => _controller.animateTo(i),
        text: widget.tabs[i].text,
        brightness: _brightness ??
            (_color.computeLuminance() > 0.5
                ? Brightness.dark
                : Brightness.light),
      );
    }

    return tabWidgets;
  }
}

class ShiftingTab {
  ShiftingTab({
    this.key,
    this.text,
    this.icon,
  });

  final Key key;
  final String text;
  final Icon icon;
}

class _ShiftingTabWidget extends AnimatedWidget {
  const _ShiftingTabWidget({
    Key key,
    Animation<double> animation,
    this.onTap,
    this.text,
    this.icon,
    this.margin,
    this.brightness,
  }) : super(key: key, listenable: animation);

  final Function onTap;
  final String text;
  final Icon icon;
  final double margin;
  final Brightness brightness;

  int get iconSize => 19;
  int get textSize => 16;

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable;
    final Color color = brightness == Brightness.dark
        ? Color.lerp(Colors.white54, Colors.white, animation.value)
        : Color.lerp(Colors.black54, Colors.black, animation.value);

    return Expanded(
      flex:
          (Tween<double>(begin: 1.0, end: 2.0).animate(animation).value * 1000)
              .round(),
      child: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: onTap,
        child: _buildTab(animation, color, margin, Directionality.of(context)),
      ),
    );
  }

  Widget _buildTab(Animation<double> animation, Color color, double margin,
      TextDirection dir) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        _buildIcon(color, margin, dir),
        _buildText(animation, color, dir),
      ],
    );
  }

  Widget _buildIcon(Color color, double margin, TextDirection dir) {
    return Container(
      margin: dir == TextDirection.ltr
          ? EdgeInsets.only(left: margin)
          : EdgeInsets.only(right: margin),
      child: IconTheme.merge(
        data: IconThemeData(
          color: color,
          size: iconSize.toDouble(),
        ),
        child: icon,
      ),
    );
  }

  Widget _buildText(
      Animation<double> animation, Color color, TextDirection dir) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        child: Container(
          margin: dir == TextDirection.ltr
              ? const EdgeInsets.only(left: 12)
              : const EdgeInsets.only(right: 12),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                DefaultTextStyle(
                  style: TextStyle(fontSize: 17, color: color),
                  child: Text(text),
                )
              ]),
        ),
        axis: Axis.horizontal,
        axisAlignment: -1.0,
        sizeFactor: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
      ),
    );
  }
}

class _ShiftingAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _ShiftingAnimation(this.controller, this.index);

  final TabController controller;
  final int index;

  @override
  Animation<double> get parent => controller.animation;

  @override
  double get value => _indexChangeProgress(controller, index);
}

/// I'm not exacly sure that what I did here. LOL
/// But the basic idea of this function is converting the value of controller
/// animation (witch is a double between 0.0 and number of tab items minus one)
/// to a double between 0.0 and 1.0 base on [index] of tab.
double _indexChangeProgress(TabController controller, int index) {
  final double controllerValue = controller.animation.value;
  final double previousIndex = controller.previousIndex.toDouble();
  final double currentIndex = controller.index.toDouble();

  /// I created this part base on some testings and I'm pretty sure this can be
  /// simplified!

  // TODO: Simplify this part
  if (index != currentIndex && index != previousIndex) {
    if (controller.indexIsChanging)
      return 0.0;
    else if (controller.offset < 0 && index == controller.index - 1)
      return controller.offset.abs().clamp(0.0, 1.0);
    else if (controller.offset > 0 && index == controller.index + 1)
      return controller.offset.abs().clamp(0.0, 1.0);
    else
      return 0.0;
  }

  // The controller's offset is changing because the user is dragging the
  // TabBarView's PageView to the left or right.
  if (!controller.indexIsChanging) {
    if (index == currentIndex)
      return 1.0 - controller.offset.abs().clamp(0.0, 1.0);
    else
      return (controller.index + 1 == previousIndex && controller.offset > 0) ||
              (controller.index - 1 == previousIndex && controller.offset < 0)
          ? controller.offset.abs().clamp(0.0, 1.0)
          : 0.0;
  }

  // The TabController animation's value is changing from previousIndex to currentIndex.
  final double val = (controllerValue - currentIndex).abs() /
      (currentIndex - previousIndex).abs();
  return index == currentIndex ? 1.0 - val : val;
}
