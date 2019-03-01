import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity/connectivity.dart';


void main() => runApp(App());

class App extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: BarQRScanner(),
      ),
    );
  }
}

class Archive extends StatefulWidget{
  @override
  _Archive createState() => _Archive();
}

class _Archive extends State<Archive>{
  final GlobalKey<ScaffoldState> _scaffoldArchive = GlobalKey<ScaffoldState>();
  List<String> _list;

  @override
  void initState() {
    super.initState();
    _getList();
  }

  _getList() async{
    SharedPreferences pref = await SharedPreferences.getInstance();
      _list = pref.getStringList('codeList') ?? List();
      setState((){});
  }

  _save() async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setStringList('codeList', _list);
  }

  _open(String text) async{
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      _scaffoldArchive.currentState.showSnackBar(SnackBar(content: Text('No internet connection')));
      return;
    }
    String url = '';
    if(text.substring(0,4) != 'http') url = 'https://www.google.com/search?q=' + text;
    else url = text;
    if(await canLaunch(url)){
      await launch(url);
    }else{
      _scaffoldArchive.currentState.showSnackBar(SnackBar(content: Text('Could not launch $text')));
    }
  }

  Widget _item(String text){
    return ListTile(
      leading: Icon(Icons.launch, size: 14.0, color: Colors.black54),
      title: SizedBox(
        child: Text(
          text,
          style: TextStyle(color: Colors.black87, fontSize: 18.0, fontFamily: 'IstokWeb-Regular'),
        ),
      ),
      onTap: (){_open(text);},
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldArchive,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: _list.length,
              itemBuilder: (context, index){
                final item = _list[index];
                return Dismissible(
                  key: Key(item),
                  onDismissed: (direction){
                    setState(() {
                      _list.removeAt(index);
                    });
                    _save();
                  },
                  background: ListTile(
                    leading: Icon(Icons.delete, color: Colors.black54,),
                    trailing: Icon(Icons.delete, color: Colors.black54,),
                  ),
                  child: _item(item),
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'close',
          child: Icon(Icons.close, size: 25.0, color: Colors.white70,),
          onPressed: (){Navigator.pop(context);},
          backgroundColor: Color.fromRGBO(65, 134, 247, 1.0),
          elevation: 1.0,
        ),
      ),
    );
  }
}

class BarQRScanner extends StatefulWidget{
  @override
  _BarQR createState() => _BarQR();
}

class _BarQR extends State<BarQRScanner>{
  final GlobalKey<ScaffoldState> _scaffoldBarQR = GlobalKey<ScaffoldState>();
  String _result = '';
  bool _autoStart = false;

  @override
  void initState(){
    super.initState();
    _init();
  }

  _init() async{
    SharedPreferences pref = await SharedPreferences.getInstance();
      _autoStart = pref.getBool('autoStart') ?? false;
      setState((){});
  }

  _saveList(String item) async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    List<String> list = pref.getStringList('codeList') ?? List();
    list.add(item);
    pref.setStringList('codeList', list);
  }

  _scan() async{
    try{
      String _resultQR = await BarcodeScanner.scan();
      setState(() {_result = _resultQR;});
      _saveList(_result);
      if(_autoStart) _open();
    }on FormatException{
      _scaffoldBarQR.currentState.showSnackBar(SnackBar(content: Text('Scan aborted')));
    }on PlatformException catch(e){
      if(e.code == BarcodeScanner.CameraAccessDenied){
        _scaffoldBarQR.currentState.showSnackBar(SnackBar(content: Text('No camera permission')));
      }else{
        _scaffoldBarQR.currentState.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }catch(e){
      _scaffoldBarQR.currentState.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  _open() async{
    if(_result == '') return;
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      _scaffoldBarQR.currentState.showSnackBar(SnackBar(content: Text('No internet connection')));
      return;
    }
    String url = '';
    if(_result.substring(0,4) != 'http') url = 'https://www.google.com/search?q=' + _result;
    else url = _result;
    if(await canLaunch(url)){
      await launch(url);
    }else{
      _scaffoldBarQR.currentState.showSnackBar(SnackBar(content: Text('Could not launch $_result')));
    }
  }

  _archive(){
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Archive())
    );
  }

  _auto() async{
    setState(() {
      _autoStart = !_autoStart;
    });
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool('autoStart', _autoStart);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldBarQR,
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Checkbox(
                        value: _autoStart,
                        onChanged: (bool){_auto();},
                      ),
                      Text(
                          'open automatically',
                          style: TextStyle(color: Colors.black87, fontSize: 16.0, fontFamily: 'IstokWeb-Regular')
                      )
                    ],
                  ),
                  SizedBox(height: 100.0,),
                  Center(
                    child: Text(
                        _result,
                        style: TextStyle(color: Colors.black87, fontSize: 20.0, fontFamily: 'IstokWeb-Regular')
                    ),
                  ),
                  Expanded(child: Container(),)
                ],
              ),
            )
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SizedBox(
                width:60.0,
                height: 60.0,
                child: FloatingActionButton(
                  heroTag: 'archive',
                  child: Icon(Icons.archive, size: 30.0, color: Colors.white70,),
                  onPressed: _archive,
                  backgroundColor: Color.fromRGBO(255, 62, 48, 1.0),
                  elevation: 1.0,
                )
            ),
            SizedBox(width: 10.0,),
            SizedBox(
                width: 90.0,
                height: 90.0,
                child: FloatingActionButton(
                  heroTag: 'party_mode',
                  child: Icon(Icons.party_mode, size: 50.0, color: Colors.white70,),
                  onPressed: _scan,
                  backgroundColor: Color.fromRGBO(23, 156, 82, 1.0),
                  elevation: 1.0,
                )
            ),
            SizedBox(width: 10.0,),
            SizedBox(
                width: 70.0,
                height: 70.0,
                child: FloatingActionButton(
                  heroTag: 'open_in_browser',
                  child: Icon(Icons.open_in_browser, size: 40.0, color: Colors.white70,),
                  onPressed: _open,
                  backgroundColor: Color.fromRGBO(247, 181, 41, 1.0),
                  elevation: 1.0,
                )
            )
          ],
        ),
      ),
    );
  }
}