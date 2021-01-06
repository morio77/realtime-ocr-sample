import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class RealtimeOcrCamera extends StatefulWidget {

  @override
  _RealtimeOcrCameraState createState() => _RealtimeOcrCameraState();
}

class _RealtimeOcrCameraState extends State<RealtimeOcrCamera> {

  /// OCRした文字
  var ocrText = '';

  /// カメラコントローラー
  CameraController cameraController;

  /// テキスト検出処理の途中かどうか
  bool detecting = false;


  @override
  void initState() {
    super.initState();

    _initializeCamera();
    
  }

  /// カメラのInitialize処理などを行う関数
  Future<void> _initializeCamera() async {

    // 使用可能なカメラを取得して、カメラコントローラーのインスタンス生成
    final cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);

    // カメラコントローラーの初期化
    await cameraController.initialize();

    // カメラの映像の取り込み開始
    await cameraController.startImageStream(_detectText);
  }

  /// テキストを検出する関数
  _detectText(CameraImage availableImage) async {
    // 前呼ばれたテキスト検出処理が終わってない場合は、即return
    if (detecting) {
      return;
    }

    // 検出中フラグを立てておく
    detecting = true;

    // スキャンしたイメージをFirebaseMLで使える形式に変換する
    final metadata = FirebaseVisionImageMetadata(
      rawFormat: availableImage.format.raw,
      size: Size(availableImage.width.toDouble(), availableImage.height.toDouble(),),
      planeData: availableImage.planes.map((currentPlane) => FirebaseVisionImagePlaneMetadata(
        bytesPerRow: currentPlane.bytesPerRow,
        height: currentPlane.height,
        width: currentPlane.width,
      ),).toList(),
    );

    final visionImage = FirebaseVisionImage.fromBytes(
      availableImage.planes.first.bytes,
      metadata,
    );

    // テキストを検出する
    final textRecognizer = FirebaseVision.instance.textRecognizer();
    final visionText = await textRecognizer.processImage(visionImage);

    // 検出中フラグを下げる
    detecting = false;

    setState(() {
      ocrText = visionText.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            /// カメラコントローラーの初期化が終わっていたらCameraPreviewを表示
            (cameraController != null && cameraController.value.isInitialized) ?
            AspectRatio(
                aspectRatio:
                cameraController.value.aspectRatio,
                child: CameraPreview(cameraController)) :
            Container(),

            /// 適当にOCRテキストを表示
            Positioned(
              bottom: 100,
              child: Text(
                ocrText,
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 40.0,
                ),
              ),
            ),
          ],
        )
    );
  }
}