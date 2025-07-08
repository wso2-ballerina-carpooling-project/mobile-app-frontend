import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/models/RideData.dart';
import 'package:mobile_frontend/services/ride_services.dart';
import 'package:mobile_frontend/widgets/driver/cancel_ride_card.dart';
import 'package:mobile_frontend/widgets/driver/ride_card.dart';
import 'package:mobile_frontend/widgets/passenger/passenger_card.dart';
import 'package:mobile_frontend/widgets/simple_ride_card.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  String? _userRole;
  bool _isLoading = true;
  List<Ride> _ongoingRides = [];
  List<Ride> _completedRides = [];
  List<Ride> _canceledRides = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserRoleAndRides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRoleAndRides() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      Map<String, dynamic> payload = Jwt.parseJwt(token);
      if (mounted) {
        setState(() {
          _userRole = payload['role']?.toString();
        });
      }

      // Fetch Ongoing rides first
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      if (_userRole == 'driver') {
        _ongoingRides = await RideService.fetchDriverOngoing(_storage);
      } else if (_userRole == 'passenger') {
        _ongoingRides = await RideService.fetchPassengerOngoing(_storage);
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Fetch Completed rides second
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      if (_userRole == 'driver') {
        _completedRides = await RideService.fetchDriverCompleted(_storage);
      } else if (_userRole == 'passenger') {
        _completedRides = await RideService.fetchPassengerCompleted(_storage);
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Fetch Canceled rides last
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      if (_userRole == 'driver') {
        _canceledRides = await RideService.fetchDriverCanceled(_storage);
      } else if (_userRole == 'passenger') {
        _canceledRides = await RideService.fetchPassengerCanceled(_storage);
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user role or rides: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                controller: _tabController,
                indicatorColor: companyColor,
                indicatorWeight: 3.0,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Ongoing'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Canceled'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOngoingContent('Ongoing', _ongoingRides),
                          _buildTabContent('Completed', _completedRides),
                          _buildCancelContent('Canceled', _canceledRides),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 8.0,
      ),
      child: Text(
        'Activities',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabContent(String tabName, List<Ride> rides) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: rides.isNotEmpty
          ? ListView.builder(
              itemCount: rides.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: _userRole == 'driver'
                      ? (index == 0
                          ? RideCard(ride: rides[index])
                          : SimpleRideCard(ride: rides[index]))
                      : PassengerRideCard(ride: rides[index]),
                );
              },
            )
          : Center(
              child: Text(
                'No $tabName activities',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
            ),
    );
  }

  Widget _buildOngoingContent(String tabName, List<Ride> rides) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: rides.isNotEmpty
          ? ListView.builder(
              itemCount: rides.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: _userRole == 'driver'
                      ? SimpleRideCard(ride: rides[index])
                      : PassengerRideCard(ride: rides[index]),
                );
              },
            )
          : Center(
              child: Text(
                'No $tabName activities',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
            ),
    );
  }
  Widget _buildCancelContent(String tabName, List<Ride> rides) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: rides.isNotEmpty
          ? ListView.builder(
              itemCount: rides.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: _userRole == 'driver'
                      ? SimpleCancelRideCard(ride: rides[index])
                      : PassengerRideCard(ride: rides[index]),
                );
              },
            )
          : Center(
              child: Text(
                'No $tabName activities',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
            ),
    );
  }
}