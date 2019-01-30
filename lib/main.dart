/// Fuzzy application written by Jason Vega. Started on December 23, 2018.

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
//import 'package:flutter/rendering.dart';

void main() {
  //debugPaintSizeEnabled = true;

  runApp(FuzzyApp());
}

/// The root of this application.
class FuzzyApp extends StatelessWidget {
  /// Returns the MaterialApp being built in the given BuildContext [context].
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuzzy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(
        storage: DataStorage()
      ),
    );
  }
}

/// Represents a connection to local data storage for memories.
class DataStorage {
  /// Gets the local path to the documents directory.
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  /// Returns a reference to the data file location.
  Future<File> get _localFile async {
    final path = await _localPath;

    return File('$path/data.json');
  }

  /// Returns the array of memories saved in the data file.
  Future<List<Memory>> getMemories() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      Map<String, dynamic> jsonData = jsonDecode(contents);
      List<dynamic> jsonMemories = jsonData["memories"];

      return jsonMemories.map((dynamic memory) {
        return Memory.fromJson(jsonDecode(memory));
      }).toList();
    }
    catch (e) {
      /// On error, return an empty list.
      print(e);
      return [];
    }
  }

  /// Overwrite memory data file.
  Future<File> saveMemories(List<Memory> memories) async {
    final file = await _localFile;

    List<String> currentMemoriesAsJson = memories.map((Memory m) {
      return jsonEncode(m);
    }).toList();

    String newJsonData = jsonEncode({"memories": currentMemoriesAsJson});

    return file.writeAsString('$newJsonData');
  }
}

/// Represents information on a positive memory.
class Memory {
  String comment;
  String author;
  DateTime date;
  bool deleted = false;

  /// Construct a new Memory with the specified [comment], [author] and [date].
  Memory(this.comment, this.author, this.date);

  /// Construct a memory from a JSON object [json]
  Memory.fromJson(Map<String, dynamic> json) :
      this.comment = json["comment"],
      this.author = json["author"],
      this.date = DateTime.parse(json["date"]),
      this.deleted = json["deleted"];

  /// Returns a JSON object representation of this Memory.
  Map<String, dynamic> toJson() =>
      {
        "comment": this.comment,
        "author": this.author,
        "date": this.date.toIso8601String(),
        "deleted": this.deleted
      };

  /// Returns date and time as a formatted String.
  static String dateTimeToString(BuildContext context, DateTime date) =>
      date.month.toString() + "/" + date.day.toString() +
          "/" + date.year.toString() + " at " +
          TimeOfDay.fromDateTime(date).format(context);
}

/// Represents a physical display of a Memory.
class MemoryCard extends StatelessWidget {
  static const int MAX_COMMENT_LINES = 3;
  static const int MAX_AUTHOR_LINES = 1;

  static const double COMMENT_FONT_SIZE = 24;
  static const double AUTHOR_FONT_SIZE = 20;
  static const double DATE_FONT_SIZE = 17;

  static const double AUTHOR_LINE_HEIGHT = 1.5;

  static const double CARD_PADDING = 10;
  static const double CARD_HORIZONTAL_MARGIN = 12;
  static const double CARD_VERTICAL_MARGIN = CARD_HORIZONTAL_MARGIN / 2;

  final Memory memory;

  /// Construct a new MemoryCard from the given [memory].
  MemoryCard(this.memory) : super(key: ObjectKey(memory));

  /// Returns a Card representation for this MemoryCard's memory being built in
  /// the given BuildContext [context].
  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: EdgeInsets.all(CARD_PADDING),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(this.memory.comment,
                      style: TextStyle(
                          fontSize: COMMENT_FONT_SIZE,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.left,
                      maxLines: MAX_COMMENT_LINES,
                      overflow: TextOverflow.ellipsis),
                  Text("— ${this.memory.author}",
                      style: TextStyle(
                          fontSize: AUTHOR_FONT_SIZE,
                          height: AUTHOR_LINE_HEIGHT),
                      textAlign: TextAlign.right,
                      maxLines: MAX_AUTHOR_LINES,
                      overflow: TextOverflow.ellipsis),
                  Text(Memory.dateTimeToString(context, this.memory.date),
                      style: TextStyle(fontSize: DATE_FONT_SIZE),
                      textAlign: TextAlign.right)
                ]
            )
        ),
        margin: EdgeInsets.symmetric(
            vertical: CARD_VERTICAL_MARGIN,
            horizontal: CARD_HORIZONTAL_MARGIN
        )
    );
  }
}

/// Detail screen for a MemoryCard.
class DetailScreen extends StatefulWidget {
  final Memory memory;
  final List<Memory> memories;
  final DataStorage storage;

  /// Construct a new DetailScreen to display info on the Memory [memory] stored
  /// in [storage].
  DetailScreen({Key key, @required this.memory, @required this.memories,
    @required this.storage}) :
        super(key: key);

  /// Create the state for this DetailScreen.
  @override
  _DetailScreenState createState() => _DetailScreenState();
}

/// The state for a DetailScreen.
class _DetailScreenState extends State<DetailScreen> {
  static const double SCREEN_PADDING = 16;

  static const double COMMENT_FONT_SIZE = 28;
  static const double AUTHOR_FONT_SIZE = 24;
  static const double DATE_FONT_SIZE = 20;

  static const int RESTORE_BUTTON_INDEX = 1;

  /// Move this memory to trash.
  Future<void> moveMemoryToTrash() async {
    this.widget.memory.deleted = true;

    this.widget.storage.saveMemories(this.widget.memories);
  }

  /// Permanently delete this memory.
  Future<void> deleteMemory() async {
    this.widget.memories.remove(this.widget.memory);

    this.widget.storage.saveMemories(this.widget.memories);
  }

  /// Remove this memory from the trash.
  Future<void> restoreMemory() async {
    this.widget.memory.deleted = false;

    this.widget.storage.saveMemories(this.widget.memories);
  }

  /// Return a list of screen actions based on whether or not the memory is
  /// currently in the trash.
  List<Widget> getScreenActions(BuildContext context) {
    List<Widget> actions = [
      IconButton(
          icon: Icon(Icons.edit),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(
                    builder: (context) => AddMemoryScreen(
                      memories: this.widget.memories,
                      storage: this.widget.storage,
                      memoryToEdit: this.widget.memory
                    )
                )
            );
          }
      ),
      IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            if (!this.widget.memory.deleted) { // Memory is not in trash can
              this.moveMemoryToTrash();
            }
            else {
              this.deleteMemory();
            }

            // Return home
            Navigator.pop(context);
          }
      )
    ];

    if (this.widget.memory.deleted) { // Memory is already in trash can
      actions.insert(RESTORE_BUTTON_INDEX, IconButton(
        icon: Icon(Icons.restore_from_trash),
        onPressed: () {
          this.restoreMemory();

          // Return home
          Navigator.pop(context);
        }
      ));
    }

    return actions;
  }

  /// Returns the screen layout being built in the given BuildContext [context].
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: getScreenActions(context)
        ),
        body: ListView(
            padding: EdgeInsets.all(SCREEN_PADDING),
            children: <Widget>[
              Text("\"${this.widget.memory.comment}\"",
                  style: TextStyle(
                      fontSize: COMMENT_FONT_SIZE,
                      fontStyle: FontStyle.italic)),
              Text(
                "— ${this.widget.memory.author}",
                style: TextStyle(fontSize: AUTHOR_FONT_SIZE),
                textAlign: TextAlign.right,
              ),
              Text(
                Memory.dateTimeToString(context, this.widget.memory.date),
                style: TextStyle(fontSize: DATE_FONT_SIZE),
                textAlign: TextAlign.right,
              )
            ]
        )
    );
  }
}

/// A screen to add a new Memory.
class AddMemoryScreen extends StatelessWidget {
  final List<Memory> memories;
  final DataStorage storage;
  final Memory memoryToEdit;

  /// Create a new AddMemoryScreen where current memories are [memories] stored
  /// in [storage].
  AddMemoryScreen({Key key, @required this.memories, @required this.storage,
    this.memoryToEdit}) :
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(this.memoryToEdit != null ?
              "Edit Memory" : "Add Memory")
        ),
        body: AddMemoryForm(
            memories: this.memories,
            storage: this.storage,
            memoryToEdit: this.memoryToEdit
        )
    );
  }
}

/// A form to add a new Memory.
class AddMemoryForm extends StatefulWidget {
  final List<Memory> memories;
  final DataStorage storage;
  final Memory memoryToEdit;

  /// Create a new AddMemoryForm where current memories are [memories] stored in
  /// [storage].
  AddMemoryForm({Key key, @required this.memories, @required this.storage,
    this.memoryToEdit}) :
        super(key: key);

  /// Create the state for this AddMemoryForm.
  @override
  _AddMemoryFormState createState() => _AddMemoryFormState();
}

/// Contains the state of an AddMemoryForm.
class _AddMemoryFormState extends State<AddMemoryForm> {
  static const double SCREEN_PADDING = 16;
  static const double INPUT_VERTICAL_PADDING = SCREEN_PADDING;
  static const int EPOCH_YEAR = 1970;

  final _addMemoryFormKey = GlobalKey<FormState>();

  final TextEditingController commentController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  DateTime _chosenDate;

  /// Initialize the state of this _AddMemoryFormState.
  @override
  void initState() {
    super.initState();

    commentController.text = this.widget.memoryToEdit != null ?
      this.widget.memoryToEdit.comment : "";
    authorController.text = this.widget.memoryToEdit != null ?
      this.widget.memoryToEdit.author : "";

    _chosenDate = this.widget.memoryToEdit != null ?
      this.widget.memoryToEdit.date : null;
  }

  /// Clean up any resources used by the controllers.
  @override
  void dispose() {
    commentController.dispose();
    authorController.dispose();
    dateController.dispose();

    super.dispose();
  }

  /// Save this [memory] to the data file.
  Future<void> saveMemory(Memory memory) async {
    this.widget.memories.add(memory);

    this.widget.storage.saveMemories(this.widget.memories);
  }

  /// Edit this [memory] and save the edit to the data file.
  Future<void> editMemory(Memory memory, String comment, String author,
      DateTime date) async {
    memory.comment = comment;
    memory.author = author;
    memory.date = date;

    this.widget.storage.saveMemories(this.widget.memories);
  }

  /// Returns the screen layout being built in the given BuildContext [context].
  @override
  Widget build(BuildContext context) {
    dateController.text = this._chosenDate != null ?
        Memory.dateTimeToString(context, this._chosenDate) : "";

    return Form(
        key: _addMemoryFormKey,
        child: Padding(
            padding: EdgeInsets.all(SCREEN_PADDING),
            child: Column(
                children: <Widget>[
                  TextFormField(
                      controller: commentController,
                      decoration: InputDecoration(
                        suffixIcon: Icon(Icons.comment),
                        border: OutlineInputBorder(),
                        labelText: "Comment"
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Please enter a comment.";
                        }
                      }
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: INPUT_VERTICAL_PADDING
                      ),
                      child: TextFormField(
                          controller: authorController,
                          decoration: InputDecoration(
                              suffixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                              labelText: "Author"
                          ),
                          validator: (value) {
                            if (value.isEmpty) {
                              return "Please enter an author.";
                            }
                          }
                      )
                  ),
                  FlatButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showDatePicker(
                            context: context,
                            initialDate: this._chosenDate != null?
                              this._chosenDate : DateTime.now(),
                            firstDate: DateTime(EPOCH_YEAR),
                            lastDate: DateTime.now()
                        ).then((DateTime chosenDate) {
                          if (chosenDate != null) {
                            showTimePicker(
                                context: context,
                                initialTime: this._chosenDate != null?
                                  TimeOfDay.fromDateTime(this._chosenDate) :
                                  TimeOfDay.now(),
                            ).then((TimeOfDay chosenTime) {
                              if (chosenTime != null) {
                                setState(() {
                                  this._chosenDate = DateTime(
                                      chosenDate.year,
                                      chosenDate.month,
                                      chosenDate.day,
                                      chosenTime.hour,
                                      chosenTime.minute
                                  );
                                });
                              }
                            });
                          }
                        });
                      },
                      child: TextFormField(
                          controller: dateController,
                          enabled: false,
                          decoration: InputDecoration(
                              suffixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                              disabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey[600]
                                )
                              ),
                              errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.red
                                  )
                              ),
                              errorStyle: TextStyle(
                                color: Colors.red
                              ),
                              labelText: "Date",
                              labelStyle: TextStyle(
                                color: Colors.grey[600]
                              )
                          ),
                          validator: (value) {
                            if (value.isEmpty) {
                              return "Please select a date.";
                            }
                          }
                      )
                  ),
                  RaisedButton(
                      onPressed: () {
                        if (_addMemoryFormKey.currentState.validate()) {
                          if (this.widget.memoryToEdit != null) {
                            this.editMemory(this.widget.memoryToEdit,
                                commentController.text,
                                authorController.text,
                                this._chosenDate);

                            /// Return to original detail screen.
                            Navigator.pop(context);
                          }
                          else {
                            Memory memory = Memory(commentController.text,
                                authorController.text,
                                this._chosenDate);

                            this.saveMemory(memory);

                            /// Opens new detail screen of new memory. Back
                            /// button pressed on detail screen returns to home
                            /// screen.
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        DetailScreen(
                                          memory: memory,
                                          memories: this.widget.memories,
                                          storage: this.widget.storage
                                        )
                                )
                            );
                          }
                        }
                      },
                      child: Text('Save')
                  )
                ]
            )
        )
    );
  }
}

/// Represents a trash can filled with deleted memories.
class TrashScreen extends StatefulWidget {
  final List<Memory> memories;
  final DataStorage storage;

  /// Create a new TrashScreen where current memories are [memories] stored in
  /// [storage].
  TrashScreen({Key key, @required this.memories, @required this.storage}) :
        super(key: key);

  /// Create the state for this TrashScreen.
  @override
  _TrashScreenState createState() => _TrashScreenState();
}

/// The state for a TrashScreen.
class _TrashScreenState extends State<TrashScreen> {
  /// Returns a list of deleted memories represented as MemoryCards.
  List<Widget> buildDeletedMemoryList() {
    return this.widget.memories.reversed.where((Memory memory) {
      return memory.deleted;
    }).map((Memory memory) {
      return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DetailScreen(
                        memory: memory,
                        memories: this.widget.memories,
                        storage: this.widget.storage
                    )
                )
            );
          },
          child: MemoryCard(memory)
      );
    }).toList();
  }

  /// Returns the screen layout being built in the given BuildContext [context].
  @override
  Widget build(BuildContext build) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trash")
      ),
      body: ListView(
        children: this.buildDeletedMemoryList()
      )
    );
  }
}

/// Home page for the Fuzzy app.
class HomeScreen extends StatefulWidget {
  final DataStorage storage;

  /// Construct a new HomeScreen with the storage location [storage] and
  /// optional Key [key].
  HomeScreen({Key key, @required this.storage}) : super(key: key);

  /// Creates the State object containing the state of this HomePage.
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

/// Contains the state of a HomePage.
class _HomeScreenState extends State<HomeScreen> {
  static const double CARD_LIST_INSET = MemoryCard.CARD_VERTICAL_MARGIN;
  static const double MEMORY_COUNT_FONT_SIZE = 40;
  static const double MEMORY_COUNT_SUBTITLE_FONT_SIZE =
      MEMORY_COUNT_FONT_SIZE / 2;
  static const double MEMORY_COUNT_PADDING = 8;

  List<Memory> memories = [];

  /// Initialize the state of this HomeScreen.
  @override
  void initState() {
    super.initState();

    this.widget.storage.getMemories().then((List<Memory> memories) {
      setState(() {
        this.memories = memories;
      });
    });
  }

  /// Returns a list of non-deleted memories represented as MemoryCards.
  List<Widget> buildMemoryList() {
    return this.memories.reversed.where((Memory memory) {
      return !memory.deleted;
    }).map((Memory memory) {
      return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DetailScreen(
                    memory: memory,
                    memories: this.memories,
                    storage: this.widget.storage
                  )
              )
            );
          },
          child: MemoryCard(memory)
        );
    }).toList();
  }

  /// Count the number of non-deleted memories saved.
  int countSaved() {
    int counter = 0;

    for (Memory memory in this.memories) {
      if (!memory.deleted) {
        counter++;
      }
    }

    return counter;
  }

  /// Count the number of memories currently in the trash.
  int countDeleted() {
    int counter = 0;

    for (Memory memory in this.memories) {
      if (memory.deleted) {
        counter++;
      }
    }

    return counter;
  }

  /// Returns the home page being built in the given BuildContext [context].
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Memories")
        ),
        body: Center(
            child: ListView(
                padding: EdgeInsets.symmetric(vertical: CARD_LIST_INSET),
                children: buildMemoryList()
            )
        ),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.cloud_queue,
                          size: MEMORY_COUNT_FONT_SIZE
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              left: MEMORY_COUNT_PADDING
                          ),
                          child: Text(
                              this.countSaved().toString(),
                              style: TextStyle(
                                fontSize: MEMORY_COUNT_FONT_SIZE,
                                fontWeight: FontWeight.w300
                              )
                            )
                        )
                      ]
                    ),
                    Text(
                        "saved " + (countSaved() == 1 ? "memory" : "memories"),
                        style: TextStyle(
                            fontSize: MEMORY_COUNT_SUBTITLE_FONT_SIZE,
                            fontWeight: FontWeight.w300
                        )
                    )
                  ],
                )
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text("Trash"),
                trailing: Text(countDeleted().toString()),
                onTap: () {
                  // Close drawer
                  Navigator.pop(context);

                  // Open trash screen
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => TrashScreen(
                          memories: this.memories,
                          storage: this.widget.storage
                      )
                  ));
                }
              )
            ]
          )
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AddMemoryScreen(
                              memories: this.memories,
                              storage: this.widget.storage
                          )
                  )
              );
            },
            tooltip: 'Add',
            child: Icon(Icons.add)
        )
    );
  }
}