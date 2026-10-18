import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
class CurrentReadingScreen extends StatefulWidget {

  const CurrentReadingScreen({super.key});


  @override
  State<CurrentReadingScreen> createState() =>
      _CurrentReadingScreenState();

}



class _CurrentReadingScreenState
    extends State<CurrentReadingScreen> {


  final currentController =
  TextEditingController();



  int? selectedIndex;



  final List<Map<String,dynamic>> readings = [

    {
      "customer":"محمد أحمد",
      "meter":"عداد نصف بوصة",
      "previous":250,
      "current":null,
      "consumption":0,
    },


    {
      "customer":"أحمد علي",
      "meter":"عداد واحد بوصة",
      "previous":400,
      "current":null,
      "consumption":0,
    },


  ];






  void calculate(){


    if(selectedIndex == null ||
        currentController.text.isEmpty){

      return;

    }


    int current =
    int.parse(
        currentController.text
    );


    int previous =
    readings[selectedIndex!]["previous"];



    setState(() {


      readings[selectedIndex!]["current"]
          = current;



      readings[selectedIndex!]["consumption"]
          =
          current - previous;



    });



    currentController.clear();


  }








  @override
  Widget build(BuildContext context) {


    return Directionality(

      textDirection:
      TextDirection.rtl,


      child: Scaffold(

        appBar:
        AppBar(

          title:
          const Text(
              "تقييم الدور"
          ),

          centerTitle:true,

        ),



        body:
        Padding(

          padding:
          const EdgeInsets.all(16),


          child:
          Column(

            children:[



              Expanded(

                child:
                ListView.builder(

                  itemCount:
                  readings.length,


                  itemBuilder:
                      (context,index){


                    final item =
                    readings[index];



                    return Card(

                      child:
                      ListTile(

                        title:
                        Text(
                          item["customer"],
                          style:
                          const TextStyle(
                              fontWeight:
                              FontWeight.bold
                          ),
                        ),



                        subtitle:
                        Text(

"""
المعدة: ${item["meter"]}

القراءة السابقة: ${item["previous"]}

القراءة الحالية: ${item["current"] ?? "-"}

الاستهلاك: ${item["consumption"]}
""",

                        ),



                        onTap: (){


                          setState(() {

                            selectedIndex =
                                index;

                          });


                        },



                        selected:
                        selectedIndex == index,


                      ),

                    );


                  },

                ),

              ),




              TextField(

                controller:
                currentController,


                keyboardType:
                TextInputType.number,


                decoration:
                const InputDecoration(

                  labelText:
                  "القراءة الحالية",

                  border:
                  OutlineInputBorder(),

                ),

              ),




              const SizedBox(height:15),




              SizedBox(

                width:
                double.infinity,


                child:
                ElevatedButton.icon(

                  onPressed:
                  calculate,


                  icon:
                  const Icon(
                      Icons.check
                  ),


                  label:
                  const Text(
                      "حفظ التقييم"
                  ),

                ),

              )



            ],

          ),

        ),

      ),

    );

  }

}