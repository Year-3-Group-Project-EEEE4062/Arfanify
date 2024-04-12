import 'package:flutter/material.dart';

class LoRaWidget extends StatefulWidget {
  final double safeScreenHeight;
  final double safeScreenWidth;
  const LoRaWidget({
    super.key,
    required this.safeScreenHeight,
    required this.safeScreenWidth,
  });

  @override
  State<LoRaWidget> createState() => _LoRaWidgetState();
}

class _LoRaWidgetState extends State<LoRaWidget> {
  //for better scaling of widgets with different screen sizes
  late double _safeVertical;
  late double _safeHorizontal;

  @override
  void initState() {
    super.initState();

    //for scaling size of the widget
    _safeVertical = widget.safeScreenHeight;
    _safeHorizontal = widget.safeScreenWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //show connection status to Medium
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 15, bottom: 15, left: 20, right: 20),
                child: Center(child: bleStatusRow(context)),
              ),
            ),
            bleTestButton(context)
          ],
        ),
      ],
    );
  }

  Row bleStatusRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(
          Icons.circle_sharp,
          size: _safeVertical * 3,
          color: Colors.green,
        ),
        SizedBox(
          width: _safeVertical * 2,
        ),
        Text(
          'Connection',
          style: TextStyle(color: Colors.white, fontSize: _safeHorizontal * 4),
        ),
      ],
    );
  }

  Row bleTestButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
            // Customize other properties like padding, border, etc.
            side: const BorderSide(
                color: Colors.black, width: 1.0), // Add an outline border
          ),
          onPressed: () async {},
          child: Text(
            'Test',
            style: TextStyle(fontSize: _safeHorizontal * 5),
          ),
        )
      ],
    );
  }
}
