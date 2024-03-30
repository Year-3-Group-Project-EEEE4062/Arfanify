import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SendAlertDialogController {
  late void Function(int) updateCounter;
}

class SendAlertDialog extends StatefulWidget {
  final int waypointLength;
  final bool autoStart;
  final SendAlertDialogController updateCounterController;
  const SendAlertDialog({
    super.key,
    required this.waypointLength,
    required this.autoStart,
    required this.updateCounterController,
  });

  @override
  State<SendAlertDialog> createState() =>
      _SendAlertDialogState(updateCounterController);
}

class _SendAlertDialogState extends State<SendAlertDialog> {
  int boatReceivedCounter = 0;

  _SendAlertDialogState(SendAlertDialogController updateCounterController) {
    updateCounterController.updateCounter = updateboatReceivedCounter;
  }

  void updateboatReceivedCounter(int num) {
    setState(() {
      boatReceivedCounter = num;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: (widget.autoStart)
          ? alreadySentTitle()
          : (boatReceivedCounter == widget.waypointLength)
              ? sentTitle()
              : sendingTitle(),
      content: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            (widget.autoStart) ? sentContent() : sendingContent(),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      actions: <Widget>[
        (boatReceivedCounter == widget.waypointLength || widget.autoStart)
            ? TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.purple),
                ),
              )
            : TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red),
                ),
              ),
      ],
    );
  }

  Text sendingContent() {
    return Text(
      "Boat received: $boatReceivedCounter / ${widget.waypointLength}",
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black,
      ),
    );
  }

  Text sentContent() {
    return const Text(
      "To send new waypoints, \ncancel exisiting operation first.",
      style: TextStyle(
        fontSize: 15,
        color: Colors.black,
      ),
    );
  }

  Row sendingTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 10),
          child: Text("Sending"),
        ),
        LoadingAnimationWidget.staggeredDotsWave(
          color: Colors.black,
          size: 20,
        ),
      ],
    );
  }

  Row sentTitle() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 10),
          child: Text("Sent"),
        ),
        Icon(
          Icons.check_sharp,
          color: Colors.green,
        ),
      ],
    );
  }

  Row alreadySentTitle() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 10),
          child: Text("Already sent"),
        ),
        Icon(
          Icons.check_sharp,
          color: Colors.green,
        ),
      ],
    );
  }
}
