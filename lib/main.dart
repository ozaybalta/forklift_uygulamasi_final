import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MyApp());
}

class UserProvider with ChangeNotifier {
  String _role = "caller"; // "caller" veya "operator"

  String get role => _role;

  void setRole(String newRole) {
    _role = newRole;
    notifyListeners();
  }
}

class CallProvider with ChangeNotifier {
  final List<Map<String, String>> callLog = [];

  void addCall(Map<String, String> call) {
    callLog.add(call);
    notifyListeners();
  }

  void acceptCall(int index) {
    callLog[index]["status"] = "Kabul Edildi";
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => CallProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String role = Provider.of<UserProvider>(context).role;

    return Scaffold(
      appBar: AppBar(title: Text("Forklift Çağırma")),
      body: role == "caller" ? CallerView() : OperatorView(),
    );
  }
}

class CallerView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RequestForkliftPage()),
            );
          },
          child: Text("Forklift Çağır"),
        ),
        SizedBox(height: 20),
        Expanded(
          child: Consumer<CallProvider>(
            builder: (context, callProvider, child) {
              return ListView.builder(
                itemCount: callProvider.callLog.length,
                itemBuilder: (context, index) {
                  final call = callProvider.callLog[index];
                  return ListTile(
                    title: Text("Forklift Tipi: ${call["forkliftType"]}"),
                    subtitle: Text("Konum: ${call["location"]}\nSaat: ${call["time"]}\nDurum: ${call["status"]}"),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class OperatorView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Operatör Ekranı")),
      body: Consumer<CallProvider>(
        builder: (context, callProvider, child) {
          return ListView.builder(
            itemCount: callProvider.callLog.length,
            itemBuilder: (context, index) {
              final call = callProvider.callLog[index];
              return ListTile(
                title: Text("Forklift Tipi: ${call["forkliftType"]}"),
                subtitle: Text("Konum: ${call["location"]}\nSaat: ${call["time"]}\nDurum: ${call["status"]}"),
                trailing: call["status"] == "Bekliyor"
                    ? ElevatedButton(
                  onPressed: () {
                    Provider.of<CallProvider>(context, listen: false).acceptCall(index);
                  },
                  child: Text("Çağrıyı Kabul Et"),
                )
                    : Text("Kabul Edildi"),
              );
            },
          );
        },
      ),
    );
  }
}

class RequestForkliftPage extends StatefulWidget {
  @override
  _RequestForkliftPageState createState() => _RequestForkliftPageState();
}

class _RequestForkliftPageState extends State<RequestForkliftPage> {
  String? selectedForklift;
  String caller = "Kullanıcı 1";
  String status = "Bekliyor";
  final List<String> forkliftTypes = ["Elektrikli", "Dizel", "LPG"];
  GoogleMapController? mapController;
  LatLng currentLocation = LatLng(39.9334, 32.8597);

  void sendCallRequest() {
    if (selectedForklift != null) {
      Provider.of<CallProvider>(context, listen: false).addCall({
        "forkliftType": selectedForklift!,
        "location": "Lat: ${currentLocation.latitude}, Lng: ${currentLocation.longitude}",
        "caller": caller,
        "status": status,
        "time": DateTime.now().toString(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Çağrı başarıyla gönderildi!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen bir forklift tipi seçin!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forklift Çağır")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLocation,
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              onTap: (LatLng location) {
                setState(() {
                  currentLocation = location;
                });
              },
              markers: {
                Marker(
                  markerId: MarkerId("currentLocation"),
                  position: currentLocation,
                )
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Forklift Tipi Seç"),
                DropdownButton<String>(
                  value: selectedForklift,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedForklift = newValue;
                    });
                  },
                  items: forkliftTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                Text("Seçilen Konum: Lat: ${currentLocation.latitude}, Lng: ${currentLocation.longitude}"),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: sendCallRequest,
                  child: Text("Çağrıyı Gönder"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}