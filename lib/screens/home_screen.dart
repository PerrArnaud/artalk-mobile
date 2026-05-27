import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/motw_provider.dart';
import '../widgets/motw_card.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMOTW());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMOTW() {
    final motwProvider = Provider.of<MOTWProvider>(context, listen: false);
    motwProvider.fetchArtTypes();
    motwProvider.fetchMOTWList(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final motwProvider = Provider.of<MOTWProvider>(context, listen: false);
      if (!motwProvider.isLoading && motwProvider.hasMore) {
        motwProvider.fetchMOTWList();
      }
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Forum'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (!authProvider.isAuthenticated) {
                return TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Login', style: TextStyle(color: Colors.white)),
                );
              }
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout();
                  } else if (value == 'profile') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.account_circle),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.user?.name ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          authProvider.user?.email ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text('Mon profil'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<MOTWProvider>(
        builder: (context, motwProvider, _) {
          if (motwProvider.isLoading && motwProvider.motwList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (motwProvider.errorMessage != null &&
              motwProvider.motwList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    motwProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMOTW,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => motwProvider.fetchMOTWList(refresh: true),
            child: Column(
              children: [
                // Barre de filtres
                if (motwProvider.artTypes.isNotEmpty)
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('Tous'),
                            selected: motwProvider.selectedArtTypeId == null,
                            onSelected: (_) => motwProvider.setArtTypeFilter(null),
                            selectedColor: Colors.deepPurple,
                            labelStyle: TextStyle(
                              color: motwProvider.selectedArtTypeId == null
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            showCheckmark: false,
                          ),
                        ),
                        ...motwProvider.artTypes.map((artType) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(artType.name),
                            selected: motwProvider.selectedArtTypeId == artType.id,
                            onSelected: (_) => motwProvider.setArtTypeFilter(
                              motwProvider.selectedArtTypeId == artType.id
                                  ? null
                                  : artType.id,
                            ),
                            selectedColor: Colors.deepPurple,
                            labelStyle: TextStyle(
                              color: motwProvider.selectedArtTypeId == artType.id
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            showCheckmark: false,
                          ),
                        )),
                      ],
                    ),
                  ),
                // Liste des œuvres
                Expanded(
                  child: motwProvider.motwList.isEmpty
                      ? const Center(child: Text('Aucune œuvre disponible'))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: motwProvider.motwList.length +
                              (motwProvider.totalPages > 1 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == motwProvider.motwList.length) {
                              if (motwProvider.isLoading) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (motwProvider.hasMore) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 24),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${motwProvider.motwList.length} / ${motwProvider.totalCount} publications',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            motwProvider.fetchMOTWList(),
                                        icon: const Icon(Icons.expand_more),
                                        label: const Text('Charger plus'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.deepPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    '${motwProvider.totalCount} publications au total',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13),
                                  ),
                                ),
                              );
                            }
                            return MOTWCard(motw: motwProvider.motwList[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
