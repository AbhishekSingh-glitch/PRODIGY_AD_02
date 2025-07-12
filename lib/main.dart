import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDir = await getApplicationDocumentsDirectory();

  Hive.init(appDocDir.path); // Hive setup
  await Hive.openBox('myBox'); // open default box

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Color bgColor = Colors.white;
  Color fontColor = Colors.black;
  List<Map> todoList= [];
  var box =Hive.box('myBox');
  String? _errorMessage;
  TextEditingController controller = TextEditingController();

  addTask({id=-1,text}){

    if(text != null){
      controller.text = text;
    }
    else{
      controller.clear();
    }
    _errorMessage = null;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context,setStateA){
            return AlertDialog(
              backgroundColor: (bgColor == Colors.white) ? Colors.white : Colors.black ,
              shadowColor: fontColor,
              title: Text('Task',style: TextStyle(color: fontColor),),
              actions: [
                TextField(
                  controller: controller,
                  maxLength: 100,
                  maxLines: 5,
                  style: TextStyle(color: fontColor ) ,
                  decoration: InputDecoration(
                    labelText: 'Type here...',labelStyle: TextStyle(color: fontColor),
                    helperStyle: TextStyle(color: fontColor),
                    border: OutlineInputBorder(),
                    counterText: '', // hides the counter
                    errorText: _errorMessage,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: Text("Cancel",style: TextStyle(color: fontColor),),
                      onPressed: () {Navigator.of(context).pop();},
                    ),
                    TextButton(
                      child: Text("OK",style: TextStyle(color: fontColor),),
                      onPressed: () {
                        if(controller.text == ''){
                          _errorMessage = "This field is required";
                          setStateA((){});
                        }
                        else {
                          if(id == -1 ){
                            todoList.add({'id': '${todoList.length}', 'text': controller.text});
                          }
                          else {
                            todoList[id]['text'] = controller.text;
                          }

                          setTodoList();

                          controller.clear();
                          Navigator.of(context).pop();
                        }
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            );
          }
        );
      },
    );
  }

  getTodoList() {
    var box = Hive.box('myBox');
    todoList = List.from( box.get('myBox') ?? [] );
  }

  setTodoList() async {
    var box = Hive.box('myBox');
    await box.put('myBox', todoList);
  }

  getBackGround() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool mode = prefs.getBool('darkMode') ?? false;
    bgColor = (mode) ? Colors.black : Colors.white;
    fontColor = (mode) ? Colors.white: Colors.black ;
  }

  @override
  void initState() {
    super.initState();
    getTodoList();
    getBackGround();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Todo List',style: TextStyle(color: fontColor),),
        backgroundColor: bgColor,
        actions: [
          IconButton(
            onPressed: () async {
              bgColor = (bgColor == Colors.white) ? Colors.black : Colors.white;
              fontColor = (bgColor == Colors.white) ? Colors.black : Colors.white;
              bool mode = (bgColor == Colors.black) ? true : false;
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setBool('darkMode', mode);
              setState(() {});
            }, icon: (bgColor == Colors.white) ? Icon(Icons.nights_stay) : Icon(Icons.sunny)
          ),
          IconButton(
            onPressed: (){addTask();},
            icon: Icon(Icons.add)
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: (bgColor == Colors.black)?
            [Colors.black ,Colors.white30,]:
            [Colors.deepOrange.shade100,Colors.white],
            radius: (bgColor == Colors.black)? 7 : 1
          )
        ),
        child: Center(
          child: Stack(
            children:[

              (todoList.isNotEmpty)?
              ListView.builder(
                itemCount: todoList.length,
                itemBuilder: (context,index){
                  return Dismissible(
                    key: ValueKey(todoList[index]),

                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),

                    onDismissed: (direction) {
                      todoList.removeAt(index);
                      setTodoList();
                      setState(() {});
                    },
                    child: GestureDetector(
                      onTap: () {
                        addTask(id: index, text: todoList[index]['text']);
                      },
                      child: Card(
                        color: Colors.black,
                        shadowColor: fontColor,
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Container(
                          height: 70,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.symmetric(horizontal: 20,vertical: 20),
                          child: Text(
                            todoList[index]['text'],
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  );

                }
              )
              :Center(
                child: Text(
                  'All Clear',
                  style: TextStyle(
                    fontSize: 20,
                    color: fontColor
                  )
                )
              ),

              Align(
                alignment:Alignment(0.95,0.8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: IconButton(
                    onPressed: (){addTask();},
                    icon: Icon(Icons.add)
                  )
                )
              )
            ]
          ),
        ),
      ),
    );
  }
}