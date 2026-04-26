import 'dart:isolate';

void main() async {
  final receivePort = ReceivePort();
  await Isolate.spawn(heavyTask, receivePort.sendPort);
  final result = await receivePort.first;
  print('Result: $result');
  
  print("Two way communication (Back & Forth)");

  final mainReceivePort = ReceivePort();
  await Isolate.spawn(worker, mainReceivePort.sendPort);
  final workerSendPort = await mainReceivePort.first as SendPort;
  final responsePort = ReceivePort();
  workerSendPort.send({"data":"Hello from main isolate!", "sendPort": responsePort.sendPort});
  final response = await responsePort.first;
  print('Response from worker: $response');
  
  print("Long-Lived Isolate with Stream");

  final streamReceivePort = ReceivePort();
  await Isolate.spawn(streamerWorker, streamReceivePort.sendPort);
  streamReceivePort.listen((message){
    if(message == "DONE"){
      streamReceivePort.close();
      return;
    }
    print("Got: $message");
  });



}

void heavyTask(SendPort sendPort) {
  int sum = 0;
  for (int i = 0; i < 1000000000; i++) {
    sum += i;
  }
  print('Sum: $sum');
  sendPort.send(sum);
}
void worker(SendPort mainSendPort){
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);
  int sum = 0;
  for (int i = 0; i < 1000000000; i++) {
    sum += i;
  }

  receivePort.listen((message){
    final data = message['data'] as String;
    final sendPort = message['sendPort'] as SendPort;
    print('Received data: $data');
    sendPort.send('Processed: $data with sum: $sum');
  });
}

int heavyCalculation(int n) {
  int sum = 0;
  for (int i = 0; i < n; i++) sum += i;
  return sum;
}

void streamerWorker(SendPort sendPort){
  for (int i =0;i<5;i++){
    Future.delayed(const Duration(seconds: 1));
    sendPort.send("Tick $i");
  }
  sendPort.send("DONE");
}