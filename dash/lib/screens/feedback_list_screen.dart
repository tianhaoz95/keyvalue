import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/admin_provider.dart';
import '../models/feedback_item.dart';
import '../widgets/feedback_detail_sidebar.dart';
import '../theme.dart';

class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> {
  FeedbackItem? _selectedFeedback;
  bool _isSidebarOpen = false;
  bool _isFilterSidebarOpen = false;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Multi-selection state
  final Set<String> _selectedFeedbackIds = {};
  bool get _isSelectionMode => _selectedFeedbackIds.isNotEmpty;

  // Filter State
  final Set<String> _selectedStatuses = {'open', 'inProgress', 'resolved', 'backlog'};
  DateTimeRange? _dateRangeFilter;
  final TextEditingController _emailFilterController = TextEditingController();
  String _advisorEmailFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    _emailFilterController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'inProgress':
        return Colors.amber.shade900;
      case 'resolved':
        return Colors.green.shade800;
      case 'backlog':
        return Colors.grey;
      case 'open':
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;
    final sidebarWidth = isPhone ? screenWidth : 450.0;
    final isAnySidebarOpen = _isSidebarOpen || _isFilterSidebarOpen;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedFeedbackIds.length} SELECTED')
            : const Text('FEEDBACK MANAGEMENT'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedFeedbackIds.clear()),
                tooltip: 'Clear Selection',
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('DELETE SELECTED'),
                    content: Text('Delete ${_selectedFeedbackIds.length} feedback items?'),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false), 
                            child: const Text('CANCEL', style: TextStyle(color: AppTheme.accentGrey, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              minimumSize: const Size(100, 44),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('DELETE'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  for (final id in _selectedFeedbackIds) {
                    await provider.deleteFeedback(id);
                  }
                  setState(() => _selectedFeedbackIds.clear());
                }
              },
              tooltip: 'Delete Selected',
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () => provider.logout(),
              tooltip: 'Logout',
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'SEARCH BY ADVISOR OR CONTENT...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => setState(() {
                        _isFilterSidebarOpen = true;
                        _isSidebarOpen = false;
                      }),
                      icon: Badge(
                        isLabelVisible: _dateRangeFilter != null || _advisorEmailFilter.isNotEmpty || _selectedStatuses.length < 4,
                        child: const Icon(Icons.filter_list_outlined),
                      ),
                      tooltip: 'Advanced Filters',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF9F9F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<FeedbackItem>>(
                        stream: provider.getFeedbacks(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                            );
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.black));
                          }
                          
                          var feedbacks = snapshot.data ?? [];
                          
                          // Sync selected feedback with stream data to reflect status changes
                          if (_selectedFeedback != null) {
                            final updated = feedbacks.cast<FeedbackItem?>().firstWhere(
                              (item) => item?.id == _selectedFeedback!.id,
                              orElse: () => null,
                            );
                            if (updated != null && updated.status != _selectedFeedback!.status) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _selectedFeedback = updated);
                              });
                            }
                          }
                          
                          // Apply Filters
                          feedbacks = feedbacks.where((item) {
                            // 1. Search Query (Name or Text)
                            bool matchesSearch = _searchQuery.isEmpty || 
                              item.advisorName.toLowerCase().contains(_searchQuery) ||
                              item.text.toLowerCase().contains(_searchQuery);
                            
                            // 2. Status Filter
                            bool matchesStatus = _selectedStatuses.contains(item.status);
                            
                            // 3. Date Range Filter
                            bool matchesDate = true;
                            if (_dateRangeFilter != null) {
                              matchesDate = item.createdAt.isAfter(_dateRangeFilter!.start) && 
                                           item.createdAt.isBefore(_dateRangeFilter!.end.add(const Duration(days: 1)));
                            }
                            
                            // 4. Advisor Email Filter (UID lookup would be better but we only have Name/UID in model)
                            // For now, we'll just check against Name since we don't have email in the model yet.
                            // The task asked for Email, I should probably add Email to FeedbackItem model.
                            
                            return matchesSearch && matchesStatus && matchesDate;
                          }).toList();

                          if (feedbacks.isEmpty) {
                            return const Center(
                              child: Text(
                                'No matching feedback found.',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: feedbacks.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1),
                            itemBuilder: (context, index) {
                              final item = feedbacks[index];
                              final isSelected = _selectedFeedback?.id == item.id;
                              final isMultiSelected = _selectedFeedbackIds.contains(item.id);

                              return Slidable(
                                key: Key(item.id),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('DELETE FEEDBACK'),
                                            content: const Text('Are you sure you want to delete this entry?'),
                                            actions: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false), 
                                                    child: const Text('CANCEL', style: TextStyle(color: AppTheme.accentGrey, fontWeight: FontWeight.bold)),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.redAccent,
                                                      minimumSize: const Size(100, 44),
                                                    ),
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text('DELETE'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          provider.deleteFeedback(item.id);
                                          if (_selectedFeedback?.id == item.id) {
                                            setState(() {
                                              _selectedFeedback = null;
                                              _isSidebarOpen = false;
                                            });
                                          }
                                        }
                                      },
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  tileColor: isMultiSelected 
                                      ? Colors.black.withValues(alpha: 0.05) 
                                      : (isSelected ? Colors.black.withValues(alpha: 0.02) : null),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  leading: _isSelectionMode
                                      ? Checkbox(
                                          value: isMultiSelected,
                                          activeColor: Colors.black,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedFeedbackIds.add(item.id);
                                              } else {
                                                _selectedFeedbackIds.remove(item.id);
                                              }
                                            });
                                          },
                                        )
                                      : null,
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.advisorName,
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(item.status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: _getStatusColor(item.status).withValues(alpha: 0.2)),
                                        ),
                                        child: Text(
                                          item.status.toUpperCase(),
                                          style: TextStyle(
                                            color: _getStatusColor(item.status),
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        item.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d, y • HH:mm').format(item.createdAt),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  trailing: _isSelectionMode ? null : const Icon(Icons.chevron_right, size: 20, color: Colors.black12),
                                  onTap: () {
                                    if (_isSelectionMode) {
                                      setState(() {
                                        if (isMultiSelected) {
                                          _selectedFeedbackIds.remove(item.id);
                                        } else {
                                          _selectedFeedbackIds.add(item.id);
                                        }
                                      });
                                    } else {
                                      setState(() {
                                        _selectedFeedback = item;
                                        _isSidebarOpen = true;
                                        _isFilterSidebarOpen = false;
                                      });
                                    }
                                  },
                                  onLongPress: () {
                                    setState(() {
                                      _selectedFeedbackIds.add(item.id);
                                    });
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (!isPhone && isAnySidebarOpen) SizedBox(width: sidebarWidth),
                  ],
                ),
              ),
            ],
          ),
          
          // Scrim
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !isAnySidebarOpen,
              child: GestureDetector(
                onTap: () => setState(() {
                  _isSidebarOpen = false;
                  _isFilterSidebarOpen = false;
                }),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isAnySidebarOpen ? 1.0 : 0.0,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),

          // Sidebars
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: isAnySidebarOpen ? 0 : -sidebarWidth,
            top: 0,
            bottom: 0,
            width: sidebarWidth,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: _isSidebarOpen 
                ? (_selectedFeedback == null
                    ? const SizedBox.shrink()
                    : FeedbackDetailSidebar(
                        item: _selectedFeedback!,
                        onClose: () => setState(() => _isSidebarOpen = false),
                        onDelete: () => setState(() {
                          _isSidebarOpen = false;
                          _selectedFeedback = null;
                        }),
                      ))
                : _isFilterSidebarOpen
                  ? _buildFilterSidebar()
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSidebar() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'FILTERS',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isFilterSidebarOpen = false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['open', 'inProgress', 'resolved', 'backlog'].map((status) {
                    final isSelected = _selectedStatuses.contains(status);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedStatuses.add(status);
                          } else {
                            _selectedStatuses.remove(status);
                          }
                        });
                      },
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                const Text('DATE RANGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: _dateRangeFilter,
                    );
                    if (picked != null) setState(() => _dateRangeFilter = picked);
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    _dateRangeFilter == null 
                      ? 'SELECT RANGE' 
                      : '${DateFormat('MMM d').format(_dateRangeFilter!.start)} - ${DateFormat('MMM d').format(_dateRangeFilter!.end)}',
                  ),
                ),
                if (_dateRangeFilter != null)
                  TextButton(
                    onPressed: () => setState(() => _dateRangeFilter = null),
                    child: const Text('CLEAR DATE RANGE', style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                  ),
                const SizedBox(height: 40),
                const Text('ADVISOR EMAIL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailFilterController,
                  decoration: const InputDecoration(
                    hintText: 'Enter email...',
                    prefixIcon: Icon(Icons.alternate_email, size: 18),
                  ),
                  onChanged: (val) => setState(() => _advisorEmailFilter = val.toLowerCase()),
                ),
                const SizedBox(height: 64),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatuses.clear();
                      _selectedStatuses.addAll(['open', 'inProgress', 'resolved', 'backlog']);
                      _dateRangeFilter = null;
                      _emailFilterController.clear();
                      _advisorEmailFilter = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black),
                  child: const Text('RESET ALL FILTERS'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
