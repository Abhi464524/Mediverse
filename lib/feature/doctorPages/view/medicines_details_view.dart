import 'package:doctor_app/feature/doctorPages/model/medicine_model.dart';
import 'package:doctor_app/feature/doctorPages/view/doctor_footer_view.dart';
import 'package:flutter/material.dart';

class MedicineDetails extends StatefulWidget {
  const MedicineDetails({super.key});

  @override
  State<MedicineDetails> createState() => _MedicineDetailsState();
}

enum SortOption { aToZ, zToA, unitsAsc, unitsDesc }

class _MedicineDetailsState extends State<MedicineDetails> {
  SortOption _currentSort = SortOption.aToZ;
  final List<MedicineModel> medicines = [
    MedicineModel(id: "1", title: "Aspirin", isAvailable: true, count: "45"),
    MedicineModel(
        id: "2", title: "Amoxicillin", isAvailable: true, count: "32"),
    MedicineModel(id: "3", title: "Metformin", isAvailable: false, count: "0"),
    MedicineModel(
        id: "4", title: "Metronidazole", isAvailable: true, count: "18"),
    MedicineModel(id: "5", title: "Albuterol", isAvailable: false, count: "0"),
  ];

  // Calculate total quantity of all medicines
  int get totalQuantity {
    return medicines.fold(0, (sum, medicine) {
      return sum + (int.tryParse(medicine.count) ?? 0);
    });
  }

  // Calculate available medicines count
  int get availableCount {
    return medicines.where((medicine) => medicine.isAvailable).length;
  }

  // Get sorted medicines list based on current sort option
  List<MedicineModel> get sortedMedicines {
    List<MedicineModel> sorted = List.from(medicines);
    switch (_currentSort) {
      case SortOption.aToZ:
        sorted.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.zToA:
        sorted.sort(
            (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortOption.unitsAsc:
        sorted.sort((a, b) =>
            (int.tryParse(a.count) ?? 0).compareTo(int.tryParse(b.count) ?? 0));
        break;
      case SortOption.unitsDesc:
        sorted.sort((a, b) =>
            (int.tryParse(b.count) ?? 0).compareTo(int.tryParse(a.count) ?? 0));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9), // Pale Mint
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent for modern look
        elevation: 0,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text("All Medicines",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              fontSize: 22,
            )),
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.filter_list),
            onSelected: (SortOption option) {
              setState(() {
                _currentSort = option;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.aToZ,
                child: Text('A-Z Sorting'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.zToA,
                child: Text('Z-A Sorting'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.unitsAsc,
                child: Text('Units ACS'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.unitsDesc,
                child: Text('Units DCS'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _summaryCard(),
          Expanded(child: _medicinesList()),
        ],
      ),
      bottomSheet: DoctorFooter(),
    );
  }

  Widget _summaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                const Color.fromRGBO(196, 218, 210, 0.5)), // Soft Sage Accent
        boxShadow: [
          const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Inventory Overview",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _countItem(
                label: "Total Items",
                count: medicines.length,
                color: const Color(0xFF6A9C89), // Sage Green
                icon: Icons.medication,
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFF2F7F5), // Soft Mint
              ),
              _countItem(
                label: "Available",
                count: availableCount,
                color: const Color(0xFF6A9C89), // Sage Green
                icon: Icons.check_circle,
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFF2F7F5), // Soft Mint
              ),
              _countItem(
                label: "Total Qty",
                count: totalQuantity,
                color: const Color(0xFF6A9C89), // Sage Green
                icon: Icons.inventory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countItem({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              "$count",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _medicinesList() {
    final sortedList = sortedMedicines;
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final medicine = sortedList[index];
        final count = int.tryParse(medicine.count) ?? 0;
        final isLowStock = count <= 10 && count > 0;
        final isOutOfStock = count == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color.fromRGBO(
                    196, 218, 210, 0.5), // Soft Sage Accent
                width: 1), // Soft Sage Accent
            boxShadow: [
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBF9), // Pale Mint
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.medication_liquid,
                  color: Color(0xFF6A9C89), // Sage Green
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? const Color.fromRGBO(
                                255, 192, 192, 0.2) // Soft Rose
                            : (isLowStock
                                ? const Color.fromRGBO(
                                    255, 229, 192, 0.4) // Soft Peach
                                : const Color.fromRGBO(
                                    196, 218, 210, 0.3)), // Soft Sage
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOutOfStock
                            ? "Out of Stock"
                            : (isLowStock ? "Low Stock" : "Available"),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOutOfStock
                              ? const Color(0xFFE57373)
                              : (isLowStock
                                  ? Colors.orange.shade800
                                  : const Color(0xFF6A9C89)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$count",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "units",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
