import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:kumi_popup_window/kumi_popup_window.dart';

class AppBarBLE extends StatefulWidget {
  const AppBarBLE({super.key});

  @override
  State<AppBarBLE> createState() => _AppBarBLEState();
}

class _AppBarBLEState extends State<AppBarBLE> {
  //These values must be able to be updated on the go
  ValueNotifier<int> counter = ValueNotifier<int>(0);
  ValueNotifier<Color> connectionColor =
      ValueNotifier<Color>(const Color.fromARGB(255, 224, 80, 70));
  ValueNotifier<String> actionMssg = ValueNotifier<String>('Idle');
  ValueNotifier<bool> showTestButton = ValueNotifier<bool>(false);

  //building a widget
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, right: 10),
      child: OutlinedButton(
        onPressed: () {
          BLEPopUp(context);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: Colors.white),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'BLE',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  KumiPopupWindow BLEPopUp(BuildContext context) {
    return showPopupWindow(
      context,
      gravity: KumiPopupGravity.rightTop,
      //curve: Curves.elasticOut,
      //bgColor: Colors.grey.withOpacity(0.5),
      clickOutDismiss: true,
      clickBackDismiss: true,
      customAnimation: false,
      customPop: false,
      customPage: false,
      //targetRenderBox: (btnKey.currentContext.findRenderObject() as RenderBox),
      needSafeDisplay: true,
      underStatusBar: false,
      underAppBar: true,
      offsetX: 0,
      offsetY: 0,
      duration: const Duration(milliseconds: 200),
      childFun: (pop) {
        return Container(
          key: GlobalKey(),
          padding: const EdgeInsets.all(10),
          height: 320,
          width: 265,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: Colors.white),
          child: Column(
            children: [
              const SizedBox(height: 10), //add space between each of them
              BLEStatusRow(context), //show connection status to Medium
              const SizedBox(height: 10),
              MediumFoundRow(context), //show how many Medium Found around
              const SizedBox(height: 10),
              ContextBox(
                  context), //show user what is currently happening in BLE
              const SizedBox(height: 10),
              BLEScanAndConnectButton(
                  context), //allow user to Scan and Connect to Medium if necessary

              //allow user to test connection if connected
              //if not connected ContextBox would alert the user
              BLETestButton(context),
            ],
          ),
        );
      },
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  void checkConnection() {
    const Color green = Color.fromARGB(255, 128, 232, 80);
    if (connectionColor.value == green) {
      //disconnected from Medium
      connectionColor.value = const Color.fromARGB(255, 224, 80, 70);
      showTestButton.value = false; //hide test button as Medium disconnected
    } else {
      //connected to Medium
      connectionColor.value = green;
      showTestButton.value = true; //allow user to test once connected
    }
  }

  Row BLEStatusRow(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 20),
        ValueListenableBuilder(
            valueListenable: connectionColor,
            builder: (context, value, _) {
              return Icon(
                Icons.circle_sharp,
                size: 20,
                color: connectionColor.value,
              );
            }),
        const SizedBox(width: 10),
        const Text(
          'Connection',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Row MediumFoundRow(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 24),
        ValueListenableBuilder(
            valueListenable: counter,
            builder: (context, value, _) {
              return Text('${counter.value}',
                  style: const TextStyle(color: Colors.black, fontSize: 20));
            }),
        const SizedBox(width: 15),
        const Text(
          'Medium Found',
          style: TextStyle(color: Colors.black, fontSize: 20),
        )
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Row ContextBox(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 24),
        Container(
            height: 100,
            width: 200,
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 197, 196, 196),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: ValueListenableBuilder(
                  valueListenable: actionMssg,
                  builder: (context, value, _) {
                    return Text(actionMssg.value,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 20));
                  }),
            ))
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Row BLEScanAndConnectButton(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 18),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text(
            'Scan & Connect',
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () {
            counter.value += 1;
            checkConnection();
          },
        ),
      ],
    );
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //displaying of this button depends on checkConnection()
  Row BLETestButton(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 14),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text(
            'Test',
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}
