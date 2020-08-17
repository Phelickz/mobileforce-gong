import 'dart:async';
import 'dart:convert';

import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:team_mobileforce_gong/models/note_model.dart';
import 'package:team_mobileforce_gong/services/auth/auth.dart';
import 'package:team_mobileforce_gong/state/authProvider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:team_mobileforce_gong/util/GongDbhelper.dart';
import 'package:uuid/uuid.dart';

class NotesProvider with ChangeNotifier {
  List<Notes> notes = [];
  var dateFormat = DateFormat("dd/MM/yy");
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json'
  };
  String error;
  bool select = false;
  List<Notes> deletes = [];
  StreamSubscription<DataConnectionStatus> createListener;
  StreamSubscription<DataConnectionStatus> updateListener;
  //StreamSubscription<DataConnectionStatus> completedListener;
  StreamSubscription<DataConnectionStatus> deleteListener;
  var uuid = Uuid();
  List<String> img = [];
  bool showNotes = true;

  void addimg(String data) {
    img.add(data);
    notifyListeners();
  }

  void setSelect() {
    select = !select;
    deletes = [];
    notifyListeners();
  }

  void addDelete(Notes note) {
    deletes.add(note);
    notifyListeners();
  }

  void removeDeletes(int index) {
    deletes.removeAt(index);
    notifyListeners();
  }

  void fetch(String uid, bool newUser) async {
    if (newUser == true) {
      await http
          .get('http://gonghng.herokuapp.com/notes/user/$uid', headers: headers)
          .then((value) async {
        var jsonres = convert.jsonDecode(value.body) as List;
        List<Notes> notess = (jsonres.map((e) => Notes.fromJson2(e)).toList());
        if (notess.isNotEmpty) {
          for (int i = 0; i < notess.length; i++) {
            print(notess[i].sId);
            GongDbhelper().insertNoteFromDb(notess[i]);
          }
        }

        await GongDbhelper().getNotes().then((value) {
          notes = value.map((e) => Notes.fromJson(e)).toList();
          notifyListeners();
        }).then((value) {});
      });
    }

    await GongDbhelper().getNotes().then((value) {
      notes = value.map((e) => Notes.fromJson(e)).toList();
      notifyListeners();
    }).then((value) {
      createDataFunc();
      updateDataFunc();
      deleteDataFunc();
    });
  }

  Future<bool> searchNotes(String query) async{
    final notesFuture =  GongDbhelper().searchNotes(query);
    List<Notes> noteList = List<Notes>();
    notesFuture.then((result) {
      print(" "+ result.length.toString() + "Length of notes");
      for (int i = 0; i < result.length; i++) {
        noteList.add(Notes.fromJson(result[i]));
      }
      if(noteList != null && noteList.length > 0 ){
        notes = noteList;
        showNotes =  true;
      }else{
        showNotes =  false;
      }
    });
  }

  void getNotes() async{
    await GongDbhelper().getNotes().then((value) {
      notes = value.map((e) => Notes.fromJson(e)).toList();
      notifyListeners();
    }).then((value) {
      createDataFunc();
      updateDataFunc();
      deleteDataFunc();
    });
    showNotes = true;
  }

  void createNote(String uid, String title, String content, bool important,
      int color,int font) async {
    print(uuid.v4());
    Notes note = new Notes(
        sId: uuid.v4(),
        title: title,
        content: content,
        font: font,
        userID: uid,
        important: important,
        date: dateFormat.format(DateTime.now()).toString(),
        uploaded: false,
        shouldUpdate: false);
    note.color = color;
    await GongDbhelper().insertNote(note).then((value) {
      notes.insert(0, note);
      notifyListeners();
    }).then((value) {
      createDataFunc();
    });
  }

  void updateNote(String uid, String title, String content, bool important,
      Notes note, int color) async {
    int index = notes.indexOf(note);
    String id = notes[index].sId;
    //print(id);
    //print(index);
    Notes unote = new Notes(
        sId: note.sId,
        title: title,
        content: content,
        userID: uid,
        important: important,
        date: note.date,
        font: note.font,
        uploaded: note.uploaded,
        shouldUpdate: true);
    unote.color = color;
    await GongDbhelper().updateNote(unote).then((value) {
      notes[index].title = title;
      notes[index].content = content;
      notes[index].important = important;
      notifyListeners();
    }).then((value) {
      updateDataFunc();
    });
  }

  void deleteNote() async {
    for (var note in deletes) {
      //print(note.sId);
      String id = note.sId;
      int index = notes.indexOf(note);

      await GongDbhelper().insertDeleteNote(note);

      await GongDbhelper().deleteNote(id).then((value) {
        notes.removeAt(index);
        notifyListeners();
      });
    }
    setSelect();
    deletes = [];
    deleteDataFunc();
  }

  Color getBackgroundColor(int backgroundColor, bool dark) {
    switch (backgroundColor) {
      case 1:
        return dark ? Colors.black : Colors.white;
        break;
      case 2:
        return Colors.red[300];
        break;
      case 3:
        return dark ? Colors.yellow[800] :Colors.yellow[400];
        break;
      case 4:
        return dark? Colors.green[400] : Colors.green[300];
        break;
      case 5:
        return dark? Colors.orange[500] : Colors.orange[300];
        break;
      case 6:
        return dark? Colors.purple[300] : Colors.purple[200];
        break;
      default:
        return dark ? Colors.black : Colors.white;
    }
  }

  void createDataFunc() {
    createListener =
        DataConnectionChecker().onStatusChange.listen((event) async {
          switch (event) {
            case DataConnectionStatus.connected:
              for (var n in notes) {
                if (!n.uploaded) {
                  await post('http://gonghng.herokuapp.com/notes',
                      body: jsonEncode({
                        'noteID': n.sId,
                        'title': n.title,
                        'content': n.content,
                        'userID': n.userID,
                        'date': n.date,
                        'important': n.important
                      }),
                      headers: headers)
                      .then((value) async {
                    if (value.statusCode == 200) {
                      Notes unote = new Notes(
                          sId: n.sId,
                          title: n.title,
                          content: n.content,
                          userID: n.userID,
                          important: n.important,
                          date: n.date,
                          uploaded: true,
                          shouldUpdate: n.shouldUpdate);
                      await GongDbhelper().updateNote(unote);

                      notes[notes.indexOf(n)].uploaded = true;
                    }
                  });
                }
              }
              createListener.cancel();
              notifyListeners();
              break;
            case DataConnectionStatus.disconnected:
              int check = 0;
              for (var n in notes) {
                if (!n.uploaded) check += 1;
              }
              if (check == 0) {
                createListener.cancel();
              }
              break;
          }
        });
  }

  void updateDataFunc() {
    updateListener =
        DataConnectionChecker().onStatusChange.listen((event) async {
          switch (event) {
            case DataConnectionStatus.connected:
              for (var n in notes) {
                if (n.shouldUpdate) {
                  await http
                      .put('http://gonghng.herokuapp.com/notes',
                      body: jsonEncode({
                        //'reminderId': todos[index].sId,
                        "noteID": n.sId,
                        'title': n.title,
                        'content': n.content,
                        'important': n.important
                      }),
                      headers: headers)
                      .then((value) async {
                    Notes unote = new Notes(
                        sId: n.sId,
                        title: n.title,
                        userID: n.userID,
                        content: n.content,
                        important: n.important,
                        date: n.date,
                        uploaded: n.uploaded,
                        shouldUpdate: false);
                    await GongDbhelper().updateNote(unote);

                    notes[notes.indexOf(n)].shouldUpdate = false;
                  });
                }
              }
              updateListener.cancel();
              notifyListeners();
              break;
            case DataConnectionStatus.disconnected:
              int check = 0;
              for (var n in notes) {
                if (n.shouldUpdate) check += 1;
              }
              if (check == 0) {
                updateListener.cancel();
              }
              break;
          }
        });
  }

  void deleteDataFunc() async {
    await GongDbhelper().getDeleteTodos().then((value) {
      deletes = value.map((e) => Notes.fromJson(e)).toList();
    }).then((value) {
      deleteListener =
          DataConnectionChecker().onStatusChange.listen((event) async {
            switch (event) {
              case DataConnectionStatus.connected:
                if (deletes.length > 0) {
                  for (var n in deletes) {
                    final request = http.Request(
                        'DELETE', Uri.parse('http://gonghng.herokuapp.com/notes'));
                    request.headers.addAll(headers);
                    request.body = jsonEncode({"noteID": n.sId});
                    await request.send().then((value) async {
                      print(value);
                      await GongDbhelper().deleteStoreTodo(n.sId).then((value) {
                        deletes.removeAt(deletes.indexOf(n));
                      });
                    });
                  }
                }
                deleteListener.cancel();
                notifyListeners();
                break;
              case DataConnectionStatus.disconnected:
                if (deletes.length == 0) {
                  deleteListener.cancel();
                }
                break;
            }
          });
    });
  }
  String getTextFont(int font)
  {
    switch(font){
      case 1:
        return "Shadows";
        break;
      case 2:
        return 'Cedarville';
        break;
      case 3:
        return 'Montserrat';
        break;
      case 4:
        return 'ComicNeue';
        break;
      case 5:
        return 'Gilroy';
        break;
      default:
        return 'Gilroy';
        break;
    }

  }
}