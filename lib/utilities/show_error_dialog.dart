
import 'package:flutter/material.dart';

Future<void>showErrorDialog(BuildContext context,String text, ){

  return showDialog(context: context, builder: (context){
    return AlertDialog(
      title:const Text('An error Occurred'),
      content: Text(text),
      actions: [
        TextButton(onPressed: (){
          Navigator.of(context).pop();
        }, child: const Text('Ok')),
      ],
    );
  });
}