import 'dart:convert';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/settings.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

part 'filemanager.g.dart';
//flutter packages pub run build_runner build

class FileManager extends StatefulWidget {

  final void Function() authenticationError;

  FileManager(this.authenticationError);

  @override
  _FileManagerState createState() => _FileManagerState(authenticationError);
}

class _FileManagerState extends State<FileManager> {
  bool _sortAscending = true;
  List<Item> _items = [];
  List<Item> _selectedItems = [];
  String pwd = "/";
  bool _saving = false;
  final void Function() authenticationError;

  _FileManagerState(this.authenticationError);


  @override
  void initState() {
    getItemsWrapper();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var l = new List<Widget>();
    l.add(getColumn());

    if (_saving) {
      var modal = new Stack(
        children: [
          new Opacity(
            opacity: 0.0,
            child: const ModalBarrier(dismissible: false, color: Colors.grey),
          ),
          new Center(
            child: new CircularProgressIndicator(),
          ),
        ],
      );
      l.add(modal);
    }

    return Stack(
      children: l,
    );
  }

  Column getColumn() {
    Column column = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      verticalDirection: VerticalDirection.down,
      children: <Widget>[
        Padding(padding: EdgeInsets.fromLTRB(5, 10, 5, 0), child: Text(pwd)),
        Expanded(
          child: dataBody(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10.0),
              child: OutlineButton(
                child: Text('SELECTED ${_selectedItems.length}'),
                onPressed: () {},
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: OutlineButton(
                child: Text('DELETE'),
                onPressed: _selectedItems.isEmpty
                    ? null
                    : () {
                        deleteSelected();
                      },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: OutlineButton(
                child: Text('LEVEL UP'),
                onPressed: () {
                  onFolderUpLevel();
                },
              ),
            ),
          ],
        ),
      ],
    );
    return column;
  }

  SingleChildScrollView dataBody() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        sortAscending: _sortAscending,
        sortColumnIndex: 0,
        columns: [
          DataColumn(
              label: Text("Name"),
              numeric: false,
              tooltip: "Folder Name",
              onSort: (int columnIndex, bool ascending) =>
                  _sort<String>((Item d) => d.name, columnIndex, ascending)),
          DataColumn(
            label: Text("Size"),
            numeric: true,
            tooltip: "File Size",
          ),
        ],
        rows: _items
            .map(
              (item) => DataRow(
                  selected: _selectedItems.contains(item),
                  onSelectChanged: (b) {
                    print("Onselect");
                    onSelectedRow(b, item);
                  },
                  cells: [
                    DataCell(
                      item.type == ItemType.folder
                          ? Row(children: <Widget>[
                              Icon(Icons.folder),
                              Text('  ' + item.name)
                            ])
                          : Text(item.name),
                      onTap: () {
                        onFolderTap(item);
                      },
                    ),
                    DataCell(Text(
                      item.size == null ? "" : item.size.toString(),
                    )),
                  ]),
            )
            .toList(),
      ),
    );
  }

  onFolderUpLevel() {
    setState(() {
      if (pwd != '/') {
        int lastPos = pwd.lastIndexOf('/');
        if (lastPos == 0) {
          pwd = '/';
        } else {
          pwd = pwd.substring(0, lastPos);
        }
      }
      getItemsWrapper();
    });
  }

  void getItemsWrapper() {
    getItems().then((items) {
      setState(() {
        _saving = false;
        _items = items;
      });
    });
  }

  onFolderTap(Item item) {
    print('Selected ${item.name}');

    if (item.type == ItemType.file) {
      return;
    }

    setState(() {
      if (pwd == '/') {
        pwd = pwd + item.name;
      } else {
        pwd = pwd + '/' + item.name;
      }

      getItemsWrapper();
    });
  }

  onSelectedRow(bool selected, Item item) async {
    setState(() {
      if (selected) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
    });
  }

  deleteSelected() async {
    Flushbar(
      message: 'Not implemented',
      duration: Duration(seconds: 1),
    )..show(context);
  }

  void _sort<T>(
      Comparable<T> getField(Item d), int columnIndex, bool ascending) {
    _items.sort((Item a, Item b) {
      if (!ascending) {
        final Item c = a;
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    setState(() {
      _sortAscending = ascending;
    });
  }

  Future<List<Item>> getItems() async {
    setState(() {
      _saving = true;
    });

    List<Item> items = List<Item>();

    try {
      var url =
          '${Settings.endpoint}/index?path=' + Uri.encodeComponent('$pwd');
      print('url $url');

      var response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": 'Bearer ${Settings.token}'
        },

        //    body: body
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        var jsonObject = json.decode(response.body);
        FolderModel folderModel = FolderModel.fromJson(jsonObject);

        pwd = folderModel.fullPath;

        folderModel.folders.forEach((folder) {
          items.add(Item(ItemType.folder, folder.name));
        });

        folderModel.files.forEach((file) {
          Item item = Item(ItemType.file, file.name);
          item.size = file.size;
          items.add(item);
        });
      } else if (response.statusCode == 403){
        print("token is not valid... routing to login page");
        authenticationError();
      } else {
        print("validation, response code: " + response.statusCode.toString());
        print("validation, body: " + response.body.toString());
      }
    } catch (e) {
      print('Error getting data: $e');
      Flushbar(
        message: 'Error getting data: $e',
        duration: Duration(seconds: 2),
      )..show(context);
    }

    return items;
  }
}

class Item {
  ItemType type;
  String name;
  int size;
  bool selected = false;

  Item(this.type, this.name);
}

enum ItemType { folder, file }

@JsonSerializable(nullable: false)
class FileModel {
  String name;
  int size;

  FileModel(this.name, this.size);

  factory FileModel.fromJson(Map<String, dynamic> json) =>
      _$FileModelFromJson(json);
}

@JsonSerializable(nullable: false)
class FolderModel {
  String fullPath;
  String name;
  List<FolderModel> folders = List<FolderModel>();
  List<FileModel> files = List<FileModel>();

  FolderModel(this.fullPath, this.name, this.folders, this.files);

  factory FolderModel.fromJson(Map<String, dynamic> json) =>
      _$FolderModelFromJson(json);
}
