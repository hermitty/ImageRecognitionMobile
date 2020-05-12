import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:async/async.dart';

class ImageInput extends StatefulWidget {
  @override
  _ImageInputState createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  Image _storedImage;
  var _isLoading = false;
  final String _apiURL = "http://5af181cc.ngrok.io/api/imagerecognition";

  uploadImageToApi(File imageFile) async {
    setState(() {
      _isLoading = true;
    });
    // open a bytestream
    var stream =
        new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var uri = Uri.parse(_apiURL);
    var request = new http.MultipartRequest("POST", uri);
    var multipartFile = new http.MultipartFile('image', stream, length,
        filename: basename(imageFile.path));
    request.files.add(multipartFile);
    var response = await request.send();

    response.stream.toBytes().then((value) {
      var image = new Image.memory(value);
      setState(() {
        _storedImage = image;
        _isLoading = false;
      });
    });
  }

  Future<void> _takePictureGallery() async {
    final imageFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );
     await _sendImage(imageFile);
  }

  Future<void> _takePicture() async {
    final imageFile = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
    );
    await _sendImage(imageFile);
  }

  Future _sendImage(File imageFile) async {
    final savedImage = await _getFileFromSource(imageFile);
    uploadImageToApi(savedImage);
  }

  Future<File> _getFileFromSource(File imageFile) async {
    final appDirectory = await syspaths.getApplicationDocumentsDirectory();
    final fileName = path.basename(imageFile.path);
    return await imageFile.copy('${appDirectory.path}/$fileName');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.8,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _storedImage != null
                        ? _storedImage
                        : Text(
                            'No Image Taken',
                            textAlign: TextAlign.center,
                          ),
                alignment: Alignment.center,
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: FlatButton.icon(
                  icon: Icon(Icons.photo),
                  label: Text('Gallery'),
                  textColor: Theme.of(context).primaryColor,
                  onPressed: _takePictureGallery,
                ),
              ),
              Expanded(
                child: FlatButton.icon(
                  icon: Icon(Icons.camera),
                  label: Text('Camera'),
                  textColor: Theme.of(context).primaryColor,
                  onPressed: _takePicture,
                ),
              ),
            ],
          ),
        ]);
  }
}
