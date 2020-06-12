import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: todoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  onPressed: addTodo,
                  color: Colors.blueAccent,
                  child: Text("Add"),
                  textColor: Colors.white,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: todoList.length,
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    readData().then((dados) {
      setState(() {
        todoList = json.decode(dados);
      });
    });
  }

  List todoList = [];

  Map<String, dynamic> lastRemoved;
  int lastRemovesPosition;

  final todoController = TextEditingController();

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> saveData() async {
    String data = json.encode(todoList);
    final file = await getFile();
    return file.writeAsString(data);
  }

  Future<String> readData() async {
    try {
      final file = await getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  void addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = todoController.text;
      newTodo["ok"] = false;
      todoController.text = "";
      todoList.add(newTodo);
      saveData();
    });
  }

  Future<Null> refresh() async {
    /* atrasa a funcao de refresh em 1 segundo para simular um servidor */
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      todoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      saveData();
    });
    return null;
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.endToStart,
      child: CheckboxListTile(
        title: Text(todoList[index]["title"]),
        value: todoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(todoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (check) {
          setState(() {
            todoList[index]["ok"] = check;
            saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          lastRemoved = Map.from(todoList[index]);
          lastRemovesPosition = index;
          todoList.removeAt(index);

          saveData();

          final snack = SnackBar(
            content: Text("${lastRemoved['title']} removida"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    todoList.insert(lastRemovesPosition, lastRemoved);
                  });
                }),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }
}
