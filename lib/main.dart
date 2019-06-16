/// Fuzzy application written by Jason Vega. Started on December 23, 2018.

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
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

  /// Returns a reference to a new image file location.
  Future<File> _createNewImageFile(File image) async {
    final path = await _localPath;
    final File newImage =
      await image.copy('$path/${Path.basename(image.path)}');

    return newImage;
  }

  /// Returns the array of memories saved in the data file.
  Future<List<Memory>> getMemories() async {
    final file = await _localFile;

    try {
      String contents = await file.readAsString();
      Map<String, dynamic> jsonData = jsonDecode(contents);
      List<dynamic> jsonMemories = jsonData["memories"];

      return jsonMemories.map((dynamic memory) {
        return Memory.fromJson(jsonDecode(memory));
      }).toList();
    }
    catch (e) {
      /// On error, create the file and return an empty list.
      file.create();
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
  String imageUrl;
  String author;
  DateTime date;
  bool deleted = false;
  bool favorite = false;

  /// Construct a new Memory with the specified [comment], [author], [date] and
  /// whether or not it is an [image].
  Memory(this.comment, this.author, this.date, [this.imageUrl]);

  /// Construct a memory from a JSON object [json]
  Memory.fromJson(Map<String, dynamic> json) :
        this.comment = json["comment"],
        this.author = json["author"],
        this.date = DateTime.parse(json["date"]),
        this.imageUrl = json["imageUrl"],
        this.deleted = json["deleted"],
        this.favorite = json["favorite"];

  /// Returns a JSON object representation of this Memory.
  Map<String, dynamic> toJson() =>
      {
        "comment": this.comment,
        "author": this.author,
        "date": this.date.toIso8601String(),
        "imageUrl": this.imageUrl,
        "deleted": this.deleted,
        "favorite": this.favorite
      };

  /// Returns date and time as a formatted String.
  static String dateTimeToString(BuildContext context, DateTime date) =>
      date.month.toString() + "/" + date.day.toString() +
          "/" + date.year.toString() + " at " +
          TimeOfDay.fromDateTime(date).format(context);

  /// Permanently delete this memory.
  Future<void> delete(List<Memory> memories, DataStorage storage) async {
    /*if (this.widget.memory.imageUrl != null) {
      File(this.widget.memory.imageUrl).delete();
    }*/

    memories.remove(this);
    storage.saveMemories(memories);
  }

  /// Remove this memory from the trash.
  Future<void> restore(List<Memory> memories,
      DataStorage storage) async {
    this.deleted = false;
    storage.saveMemories(memories);
  }

  /// Move this memory to trash.
  Future<void> moveToTrash(List<Memory> memories,
      DataStorage storage) async {
    this.deleted = true;
    storage.saveMemories(memories);
  }

  /// Add this memory to favorites list.
  Future<void> addToFavorites(List<Memory> memories,
      DataStorage storage) async {
    this.favorite = true;
    storage.saveMemories(memories);
  }

  /// Remove this memory to favorites list.
  Future<void> removeFromFavorites(List<Memory> memories,
      DataStorage storage) async {
    this.favorite = false;
    storage.saveMemories(memories);
  }
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
                  (this.memory.imageUrl != null ?
                  Image.file(File(this.memory.imageUrl)) :
                  Text(this.memory.comment,
                      style: TextStyle(
                          fontSize: COMMENT_FONT_SIZE,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.left,
                      maxLines: MAX_COMMENT_LINES,
                      overflow: TextOverflow.ellipsis)
                  ),
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

/// An AppBar widget for the DetailScreen.
class DetailScreenAppBar extends PreferredSize {
  Memory memory;
  List<Memory> memories;
  DataStorage storage;

  DetailScreenAppBar(this.memory, this.memories, this.storage);

  @override
  Size get preferredSize {
    return Size.fromHeight(kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
        actions: [
          IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AddMemoryScreen(
                              memories: this.memories,
                              storage: this.storage,
                              memoryToEdit: this.memory,
                            )
                    )
                );
              }
          ),
          IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                String message;

                if (!this.memory.deleted) { // Memory is not in trash can
                  this.memory.moveToTrash(this.memories, this.storage);
                  message = "Moved to trash.";
                }
                else {
                  this.memory.delete(this.memories, this.storage);
                  message = "Deleted.";
                }

                Navigator.pop(context, message);
              }
          ),
          Visibility(
              visible: this.memory.deleted,
              child: IconButton(
                  icon: Icon(Icons.restore_from_trash),
                  onPressed: () {
                    this.memory.restore(this.memories, this.storage);

                    Navigator.pop(context, "Restored.");
                  }
              )
          )
        ]
    );
  }
}

/// Detail screen for a MemoryCard.
class DetailScreen extends StatefulWidget {
  static const double SCREEN_PADDING = 16;

  static const double COMMENT_FONT_SIZE = 24;
  static const double AUTHOR_FONT_SIZE = 20;
  static const double DATE_FONT_SIZE = 18;

  static const int RESTORE_BUTTON_INDEX = 1;

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
  /// Returns the screen layout being built in the given BuildContext [context].
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: DetailScreenAppBar(this.widget.memory, this.widget.memories,
         this.widget.storage),
        body: ListView(
            padding: EdgeInsets.all(DetailScreen.SCREEN_PADDING),
            children: <Widget>[
              (this.widget.memory.imageUrl != null ?
              Image.file(File(this.widget.memory.imageUrl)) :
              Text("\"${this.widget.memory.comment}\"",
                  style: TextStyle(
                      fontSize: DetailScreen.COMMENT_FONT_SIZE,
                      fontStyle: FontStyle.italic)
              )
              ),
              Text(
                "— ${this.widget.memory.author}",
                style: TextStyle(fontSize: DetailScreen.AUTHOR_FONT_SIZE),
                textAlign: TextAlign.right,
              ),
              Text(
                Memory.dateTimeToString(context, this.widget.memory.date),
                style: TextStyle(fontSize: DetailScreen.DATE_FONT_SIZE),
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
  final File image;

  /// Create a new AddMemoryScreen where current memories are [memories] stored
  /// in [storage].
  AddMemoryScreen({Key key, @required this.memories, @required this.storage,
    this.memoryToEdit, this.image}) :
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
            memoryToEdit: this.memoryToEdit,
            image: (this.memoryToEdit != null &&
                this.memoryToEdit.imageUrl != null ?
                File(this.memoryToEdit.imageUrl) : this.image)
        )
    );
  }
}

/// A form to add a new Memory.
class AddMemoryForm extends StatefulWidget {
  static const double SCREEN_PADDING = 16;
  static const double INPUT_VERTICAL_PADDING = SCREEN_PADDING;
  static const int MAXIMUM_COMMENT_LINES = 5;

  final List<Memory> memories;
  final DataStorage storage;
  final Memory memoryToEdit;
  final File image;

  /// Create a new AddMemoryForm where current memories are [memories] stored in
  /// [storage].
  AddMemoryForm({Key key, @required this.memories, @required this.storage,
    this.memoryToEdit, this.image}) :
        super(key: key);

  /// Create the state for this AddMemoryForm.
  @override
  _AddMemoryFormState createState() => _AddMemoryFormState();
}

/// Contains the state of an AddMemoryForm.
class _AddMemoryFormState extends State<AddMemoryForm> {
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

    return SingleChildScrollView(
        padding: EdgeInsets.all(AddMemoryForm.SCREEN_PADDING),
        child: Form(
            key: _addMemoryFormKey,
            child: Column(
                children: <Widget>[
                  (this.widget.image != null ?
                  Image.file(this.widget.image) :
                  TextFormField(
                      controller: commentController,
                      decoration: InputDecoration(
                          suffixIcon: Icon(Icons.comment),
                          border: OutlineInputBorder(),
                          labelText: "Comment"
                      ),
                      maxLines: null,
                      //AddMemoryForm.MAXIMUM_COMMENT_LINES,
                      keyboardType: TextInputType.multiline,
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Please enter a comment.";
                        }
                      }
                  )
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        top: AddMemoryForm.INPUT_VERTICAL_PADDING
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
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        top: AddMemoryForm.INPUT_VERTICAL_PADDING
                    ),
                    child:
                    FlatButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          showDatePicker(
                              context: context,
                              initialDate: this._chosenDate != null ?
                              this._chosenDate : DateTime.now(),
                              firstDate: DateTime(EPOCH_YEAR),
                              lastDate: DateTime.now()
                          ).then((DateTime chosenDate) {
                            if (chosenDate != null) {
                              showTimePicker(
                                context: context,
                                initialTime: this._chosenDate != null ?
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
                  ),
                  Padding(
                      padding: EdgeInsets.only(
                          top: AddMemoryForm.INPUT_VERTICAL_PADDING
                      ),
                      child: RaisedButton(
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
                                Memory memory = (this.widget.image != null ?
                                Memory(commentController.text,
                                    authorController.text,
                                    this._chosenDate,
                                    this.widget.image.path) :
                                Memory(commentController.text,
                                    authorController.text,
                                    this._chosenDate)
                                );

                                this.saveMemory(memory);

                                /// Opens new detail screen of new memory. Back
                                /// button pressed on detail screen returns to
                                /// home screen.
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

/// Represents a screen displaying a list of favorite memories.
class FavoritesScreen extends StatefulWidget {
  final List<Memory> memories;
  final DataStorage storage;

  /// Create a new FavoritesScreen where current memories are [memories] stored
  /// in [storage].
  FavoritesScreen({Key key, @required this.memories, @required this.storage}) :
        super(key: key);

  /// Create the state for this FavoritesScreen.
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

/// The state for a FavoritesScreen.
class _FavoritesScreenState extends State<FavoritesScreen> {
  /// Returns a list of favorite memories represented as MemoryCards.
  List<Widget> buildFavoritesMemoryList() {
    return this.widget.memories.reversed.where((Memory memory) {
      return memory.favorite;
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
            title: Text("Favorites")
        ),
        body: ListView(
            children: this.buildFavoritesMemoryList()
        )
    );
  }
}

/// Home page for the Fuzzy app.
class HomeScreen extends StatefulWidget {
  static const double CARD_LIST_INSET = MemoryCard.CARD_VERTICAL_MARGIN;
  static const double MEMORY_COUNT_FONT_SIZE = 40;
  static const double MEMORY_COUNT_SUBTITLE_FONT_SIZE =
      MEMORY_COUNT_FONT_SIZE / 2;
  static const double MEMORY_COUNT_PADDING = 8;
  static const double BUTTONS_TEXT_PADDING = 8;
  static const double DISMISSIBLE_ICON_SIZE = 35;
  static const double DISMISSIBLE_BACKGROUND_PADDING = 30;

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
  List<Map<String, dynamic>> buildMemoryCardList() {
    return this.memories.reversed.where((Memory memory) {
      return !memory.deleted;
    }).map((Memory memory) {
      return {"card": GestureDetector(
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
      ), "memoryListIndex": this.memories.indexOf(memory)};
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

  /// Count the number of favorite memories.
  int countFavorites() {
    int counter = 0;

    for (Memory memory in this.memories) {
      if (memory.favorite) {
        counter++;
      }
    }

    return counter;
  }

  // Retrieve an image from gallery.
  Future<File> getImage() async {
    var selected = await ImagePicker.pickImage(source: ImageSource.gallery);

    return selected;
  }

  /// Returns the home page being built in the given BuildContext [context].
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> memoryCardList = this.buildMemoryCardList();

    return Scaffold(
        appBar: AppBar(
            title: Text("Memories")
        ),
        body: Center(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                  vertical: HomeScreen.CARD_LIST_INSET
              ),
              itemCount: memoryCardList.length,
              itemBuilder: (context, index) {
                final memoryCard = memoryCardList[index];
                final memory = this.memories[memoryCard["memoryListIndex"]];

                return Dismissible(
                    key: Key("MemoryCard " +
                        memoryCard["memoryListIndex"].toString()),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        setState(() {
                          memory.moveToTrash(this.memories,
                              this.widget.storage);
                        });

                        Scaffold.of(context).showSnackBar(
                            SnackBar(content: Text("Moved to trash.")));
                      }
                    },
                    confirmDismiss: (direction) {
                      bool isDeleteDirection = direction ==
                          DismissDirection.endToStart;

                      if (!isDeleteDirection) { // Add memory to favorites
                        if (!memory.favorite) {
                          setState(() {
                            memory.addToFavorites(this.memories,
                                this.widget.storage);
                          });

                          Scaffold.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Added to favorites.")
                              )
                          );
                        }
                        else {
                          setState(() {
                            memory.removeFromFavorites(this.memories,
                                this.widget.storage);
                          });

                          Scaffold.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Removed from favorites.")
                              )
                          );
                        }
                      }

                      return Future.value(isDeleteDirection);
                    },
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.all(
                          HomeScreen.DISMISSIBLE_BACKGROUND_PADDING
                      ),
                      child: Icon(
                        (memory.favorite == true ?
                        Icons.star :
                        Icons.star_border),
                        color: Colors.white,
                        size: HomeScreen.DISMISSIBLE_ICON_SIZE,
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.all(
                          HomeScreen.DISMISSIBLE_BACKGROUND_PADDING
                      ),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: HomeScreen.DISMISSIBLE_ICON_SIZE,
                      ),
                    ),
                    child: memoryCard["card"]
                );
              },
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
                                    size: HomeScreen.MEMORY_COUNT_FONT_SIZE
                                ),
                                Padding(
                                    padding: EdgeInsets.only(
                                        left: HomeScreen.MEMORY_COUNT_PADDING
                                    ),
                                    child: Text(
                                        this.countSaved().toString(),
                                        style: TextStyle(
                                            fontSize:
                                            HomeScreen.MEMORY_COUNT_FONT_SIZE,
                                            fontWeight: FontWeight.w300
                                        )
                                    )
                                )
                              ]
                          ),
                          Text(
                              "saved " + (this.countSaved() == 1 ? "memory" :
                                  "memories"),
                              style: TextStyle(
                                  fontSize:
                                  HomeScreen.MEMORY_COUNT_SUBTITLE_FONT_SIZE,
                                  fontWeight: FontWeight.w300
                              )
                          )
                        ],
                      )
                  ),
                  ListTile(
                      leading: Icon(Icons.star),
                      title: Text("Favorites"),
                      trailing: Text(this.countFavorites().toString()),
                      onTap: () {
                        // Close drawer
                        Navigator.pop(context);

                        // Open trash screen
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) =>
                                FavoritesScreen(
                                    memories: this.memories,
                                    storage: this.widget.storage
                                )
                        ));
                      }
                  ),
                  ListTile(
                      leading: Icon(Icons.delete),
                      title: Text("Trash"),
                      trailing: Text(this.countDeleted().toString()),
                      onTap: () {
                        // Close drawer
                        Navigator.pop(context);

                        // Open trash screen
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) =>
                                TrashScreen(
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
              showModalBottomSheet(context: context,
                  builder: (BuildContext context) {
                    return ButtonBar(
                        children: <Widget>[
                          Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Ink(
                                    decoration: ShapeDecoration(
                                        color: Colors.blue,
                                        shape: CircleBorder()
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.photo_album),
                                      color: Colors.white,
                                      onPressed: () {
                                        this.getImage().then((File image) {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      AddMemoryScreen(
                                                          memories:
                                                          this.memories,
                                                          storage:
                                                          this.widget
                                                              .storage,
                                                          image: image
                                                      )
                                              )
                                          );
                                        });
                                      }
                                    )
                                ),
                                Padding(
                                    padding: EdgeInsets.only(
                                        top: HomeScreen.BUTTONS_TEXT_PADDING
                                    ),
                                    child: Text(
                                        "Photo",
                                        maxLines: 1
                                    )
                                )
                              ]
                          ),
                          Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Ink(
                                    decoration: ShapeDecoration(
                                        color: Colors.blue,
                                        shape: CircleBorder()
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.edit),
                                      color: Colors.white,
                                      onPressed: () {
                                        Navigator.pushReplacement(context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    AddMemoryScreen(
                                                        memories: this.memories,
                                                        storage:
                                                          this.widget.storage
                                                    )
                                            )
                                        );
                                      },
                                    )
                                ),
                                Padding(
                                    padding: EdgeInsets.only(
                                        top: HomeScreen.BUTTONS_TEXT_PADDING
                                    ),
                                    child: Text(
                                        "Text",
                                        maxLines: 1
                                    )
                                )
                              ]
                          )
                        ]
                    );
                  }
              );
            },
            tooltip: 'Add',
            child: Icon(Icons.add)
        )
    );
  }
}