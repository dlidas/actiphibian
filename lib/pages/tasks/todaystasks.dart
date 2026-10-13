import 'package:flutter/material.dart';

class TodaysTasks extends StatelessWidget {
  const TodaysTasks({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Container(
          width: screenWidth * 0.75,
          margin: EdgeInsets.all(15),
          padding: EdgeInsets.all(20),
    
          decoration: BoxDecoration(
            color: const Color.fromARGB(207, 156, 86, 5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 81, 184, 86),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.circle, color: Colors.white, size: 20),
              ),
              SizedBox(width: 10),
    
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Tasks",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "xxxxxx",
                    style: TextStyle(fontSize: 14, color: Colors.black12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
