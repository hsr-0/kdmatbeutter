import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:untitled4/data/api/api_service.dart';
import 'package:untitled4/data/models/models.dart';
import 'package:untitled4/presentation/widgets/office_card.dart';
import 'package:untitled4/presentation/pages/representation_card.dart';
import 'package:untitled4/presentation/widgets/stats_widget.dart';
import 'package:untitled4/presentation/pages/members_screen.dart';
import 'package:untitled4/presentation/pages/regions_screen.dart';
import 'package:untitled4/presentation/pages/map_screen.dart';
import 'package:untitled4/presentation/pages/office_leaders_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

import 'chiefs_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _totalMembers = 0;
  int _totalOffices = 0;
  int _totalRepresentations = 0;
  int _currentBannerIndex = 0;
  int _totalChiefs = 0;
  int _totalVoters = 0;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  late Future<List<Office>> _officesFuture;
  late Future<List<Representation>> _representationsFuture;
  late Future<StatsResponse> _statsFuture;

  final List<String> _bannerImages = [
    'assets/banners/banner.jpg',
    'assets/banners/banner1.jpg',
    'assets/banners/banner2.jpg',
    'assets/banners/banner3.jpg',
    'assets/banners/banner4.jpg',
    'assets/banners/banner5.jpg',

  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInitialData();
    _loadStatsData();
    _testApiConnection();
  }

  Future<void> _testApiConnection() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/offices');
      final response = await http.get(url);
      debugPrint('API Connection Test: ${response.statusCode}');
    } catch (e) {
      debugPrint('API Test Error: $e');
    }
  }

  Future<void> _loadStatsData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final stats = await Provider.of<ApiService>(context, listen: false).getVotingStats();

      if (!mounted) return;

      setState(() {
        _totalChiefs = stats.data.totalChiefs;
        _totalVoters = stats.data.totalVoters;
      });
    } catch (e) {
      debugPrint('Error loading stats data: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل إحصاءات القادة والناخبين';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _officesFuture = Provider.of<ApiService>(context, listen: false).getOffices();
      _representationsFuture = Provider.of<ApiService>(context, listen: false).getRepresentations();
      _statsFuture = Provider.of<ApiService>(context, listen: false).getVotingStats();
    });

    try {
      final offices = await _officesFuture;
      final representations = await _representationsFuture;
      final stats = await _statsFuture;

      if (!mounted) return;
      setState(() {
        _totalOffices = offices.length;
        _totalRepresentations = representations.length;
        _totalMembers = offices.fold(0, (sum, office) => sum + office.totalMembers);
        _totalChiefs = stats.data.totalChiefs;
        _totalVoters = stats.data.totalVoters;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _getUserFriendlyError(e);
      });
      debugPrint('Error loading data: $e');
    }
  }

  String _getUserFriendlyError(dynamic error) {
    if (error is http.ClientException) {
      return 'تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت';
    }
    return 'حدث خطأ أثناء جلب البيانات. يرجى المحاولة لاحقاً';
  }

  Future<void> _refreshAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _loadInitialData();
    } catch (e) {
      debugPrint('Error refreshing all data: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = _getUserFriendlyError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خدمتي'),
        centerTitle: true,
        backgroundColor: Color(0xFFD5EFD5), // أخضر داكن
        actions: [
          StatsWidget(
            totalMembers: _totalMembers,
            officeCount: _totalOffices,
            representationCount: _totalRepresentations,
            totalChiefs: _totalChiefs,
            totalVoters: _totalVoters,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllData,
            tooltip: 'تحديث البيانات',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'الرئيسية'),
            Tab(icon: Icon(Icons.business), text: 'المكاتب'),
            Tab(icon: Icon(Icons.account_balance), text: 'الممثليات'),
            Tab(icon: Icon(Icons.map), text: 'الخريطة'),
            Tab(icon: Icon(Icons.people_alt), text: 'القادة'),
          ],
        ),
      ),
      body: _buildTabView(),
    );
  }

  Widget _buildTabView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOfficesTab(),
        _buildHomeTab(),
        _buildRepresentationsTab(),
        MapScreen(),
        ChiefsScreen(),
      ],
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _refreshAllData,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildEnhancedBannerSlider(),
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBannerSlider() {
    if (_bannerImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          CarouselSlider(
            items: _bannerImages.map((imagePath) {
              return Container(
                margin: const EdgeInsets.all(0),
                child: ClipRRect(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        height: 250,
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
            options: CarouselOptions(
              height: 250,
              aspectRatio: 16/9,
              viewportFraction: 1.0,
              initialPage: 0,
              enableInfiniteScroll: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              scrollDirection: Axis.horizontal,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'تحالف خدمات',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Khadamat Alliance',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'تحالف سياسي عراقي يعمل وفق الهوية الوطنية تحت شعار عدالة أتنبية أعمار',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _bannerImages.asMap().entries.map((entry) {
                return Container(
                  width: 10.0,
                  height: 10.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBannerIndex == entry.key
                        ? Color(0xFF2E7D32)
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2E7D32).withOpacity(0.8),
              Color(0xFF1B5E20),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'إحصاءات النظام',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatItem(Icons.people, 'إجمالي اعضاء ناخبين المكاتب', _totalMembers.toString(), Colors.white),
                  _buildStatItem(Icons.business, 'عدد المكاتب', _totalOffices.toString(), Colors.white),
                  _buildStatItem(Icons.account_balance, 'عدد الممثليات', _totalRepresentations.toString(), Colors.white),
                  _buildStatItem(Icons.leaderboard, 'عدد القادة', _totalChiefs.toString(), Colors.white),
                  _buildStatItem(Icons.how_to_vote, 'إجمالي الناخبين', _totalVoters.toString(), Colors.white),
                  _buildStatItem(Icons.update, 'آخر تحديث', _getLastUpdatedTime(), Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLastUpdatedTime() {
    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  }

  Widget _buildStatItem(IconData icon, String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshAllData,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficesTab() {
    return Column(
      children: [
        _buildSearchField('ابحث في المكاتب'),
        Expanded(
          child: FutureBuilder<List<Office>>(
            future: _officesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorWidget();
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState('لا توجد مكاتب متاحة');
              }

              final offices = _filterOffices(snapshot.data!);

              if (offices.isEmpty) {
                return _buildEmptyState('لا توجد نتائج مطابقة للبحث');
              }

              return _buildOfficesList(offices);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRepresentationsTab() {
    return Column(
      children: [
        _buildSearchField('ابحث في الممثليات'),
        Expanded(
          child: FutureBuilder<List<Representation>>(
            future: _representationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorWidget();
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState('لا توجد ممثليات متاحة');
              }

              final representations = _filterRepresentations(snapshot.data!);

              if (representations.isEmpty) {
                return _buildEmptyState('لا توجد نتائج مطابقة للبحث');
              }

              return _buildRepresentationsList(representations);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(String hint) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  List<Office> _filterOffices(List<Office> offices) {
    return offices.where((office) =>
    office.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        office.leader.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        office.location.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<Representation> _filterRepresentations(List<Representation> representations) {
    return representations.where((rep) =>
    rep.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        rep.leader.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        rep.location.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Widget _buildOfficesList(List<Office> offices) {
    return RefreshIndicator(
      onRefresh: _refreshAllData,
      child: ListView.builder(
        itemCount: offices.length,
        itemBuilder: (context, index) {
          final office = offices[index];
          return OfficeCard(
            key: ValueKey(office.id),
            office: office,
            onPressed: () => _navigateToOfficeLeaders(context, office),
          );
        },
      ),
    );
  }

  Widget _buildRepresentationsList(List<Representation> representations) {
    return RefreshIndicator(
      onRefresh: _refreshAllData,
      child: ListView.builder(
        itemCount: representations.length,
        itemBuilder: (context, index) {
          return RepresentationCard(
            key: ValueKey(representations[index].id),
            representation: representations[index],
            onPressed: () => _navigateToRegions(context, representations[index]),
          );
        },
      ),
    );
  }

  void _navigateToOfficeLeaders(BuildContext context, Office office) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfficeLeadersScreen(office: office),
      ),
    );
  }

  void _navigateToRegions(BuildContext context, Representation representation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegionsScreen(representation: representation),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}