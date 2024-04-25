import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shoping_list_app/data/categories.dart';
import 'package:shoping_list_app/model/grocery_item.dart';
import 'package:shoping_list_app/screens/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItem = [];
 late Future <List<GroceryItem>> _loadedItrems;
  String? _error ;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }



  Future<List<GroceryItem>>_loadItem() async {
    try{
      final url = Uri.https(
        'flutter-prep-9da75-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.get(url);

    if(response.statusCode>=400){
      setState(() {
      _error = 'Failed to Fetch Data. Please Try Again Later';
      });
    }

    if(response.body == 'null'){
      setState(() {
        _isLoading = false;
      });
      return [];
    }

    final Map<String, dynamic> listData = jsonDecode(response.body);
    final List<GroceryItem> loadedItem = [];
    
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItem.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    return loadedItem;

    }catch(err){
_error='Something went wrong ';
    }
    
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _isLoading = false;
      _groceryItem.add(newItem);
    });

  }

    void _removeItem(GroceryItem item) async {
      final index = _groceryItem.indexOf(item);
          setState(() {
            _groceryItem.remove(item);
          });
       final url = Uri.https(
        'flutter-prep-9da75-default-rtdb.firebaseio.com', 'shopping-list${item.id}.json');
           final response = await http.delete(url);
           if (response.statusCode >= 400){
            setState(() {
              _groceryItem.insert(index , item);
            });
           }
            
          }
  

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No Item added yet.'),
    );

    if (_isLoading) {
       content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder: (BuildContext context,int index) { 
          return Dismissible(
            onDismissed: (direction) {
        _removeItem(_groceryItem[index]);
        },

          key: ValueKey(_groceryItem[index].id),
          child: ListTile(
            title: Text(_groceryItem[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItem[index].category.color,
            ),
            trailing: Text(
              _groceryItem[index].quantity.toString(),
            ),
          ),
        );}
      );
    }
    if (_error != null){
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
          ],
          title: const Text('Groceries'),
        ),
        body: content);
  }
}
