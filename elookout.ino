#include "painlessMesh.h"

#define   MESH_PREFIX     "ElookoutMesh"
#define   MESH_PASSWORD   "SneakyPassword"
#define   MESH_PORT       5555

Scheduler userScheduler; // to control your personal task
painlessMesh  mesh;

// User stub
void sendMessage() ; // Prototype so PlatformIO doesn't complain

Task taskSendMessage(TASK_SECOND * 1 ,TASK_FOREVER, &sendMessage);

void sendMessage() {
  Serial.printf("Sending Message now\r\n");
  digitalWrite(LED_BUILTIN, HIGH);
  String msg = "Hello from node ";
  msg += mesh.getNodeId();
  mesh.sendBroadcast(msg);
  taskSendMessage.setInterval(random(TASK_SECOND * 1, TASK_SECOND * 5));
  digitalWrite(LED_BUILTIN, LOW);
}

// Needed for painless library
void receivedCallback( uint32_t from, String &msg ) {
  Serial.printf("RECEIVED message from %u msg=%s\r\n", from, msg.c_str());
}

void newConnectionCallback(uint32_t nodeId) {
    Serial.printf("NEW CONNECTION nodeId = %u\r\n", nodeId);
}

void changedConnectionCallback() {
    Serial.printf("CHANGED CONNECTIONS %s\r\n",mesh.subConnectionJson().c_str());
}

void nodeTimeAdjustedCallback(int32_t offset) {
    Serial.printf("ADJUSTED TIME %u. Offset = %d\r\n", mesh.getNodeTime(),offset);
}

void setup() {
  Serial.begin(115200);
  Serial.printf("Turning on!\r\n");

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  //mesh.setDebugMsgTypes(ERROR | STARTUP | MESH_STATUS | CONNECTION | SYNC | COMMUNICATION | GENERAL | MSG_TYPES | REMOTE); // all types on
  mesh.setDebugMsgTypes( ERROR | STARTUP );  // set before init() so that you can see startup messages

  mesh.init(MESH_PREFIX, MESH_PASSWORD, &userScheduler, MESH_PORT);
  mesh.onReceive(&receivedCallback);
  mesh.onNewConnection(&newConnectionCallback);
  mesh.onChangedConnections(&changedConnectionCallback);
  mesh.onNodeTimeAdjusted(&nodeTimeAdjustedCallback);

  userScheduler.addTask(taskSendMessage);
  taskSendMessage.enable();
}

void loop() {
  userScheduler.execute(); // it will run mesh scheduler as well
  mesh.update();
}
