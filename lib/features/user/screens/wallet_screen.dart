import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // App Colors matching the image
    const Color purplePrimary = Color(0xFF9053FF);
    const Color textLight = Colors.white;
    const Color incomeColor = Color(0xFF20D08F);
    const Color expenseColor = Color(0xFFFF6D6D);
    const Color iconBackground = Color(0xFFF6F6F6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content layout
          CustomScrollView(
            slivers: [
              // Top Purple Header Section
              SliverToBoxAdapter(
                child: ClipPath(
                  // clipper: CustomHeaderClipper(),
                  child: Container(
                    color: purplePrimary,
                    padding: const EdgeInsets.only(top: 50, bottom: 45),
                    child: Column(
                      children: [
                        // Custom App Bar Action Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(
                                  'https://unsplash.com',
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.notifications_none,
                                color: textLight,
                                size: 24,
                              ),
                              const Spacer(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Wallet',
                                    style: TextStyle(
                                      color: textLight,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: textLight),
                                ],
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: textLight,
                                size: 22,
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.search,
                                color: textLight,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Month Selector Carousel Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildMonthItem('AUG 2018', false),
                              _buildMonthItem('SEP 2018', true),
                              _buildMonthItem('OCT 2018', false),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Balance Display
                        const Text(
                          'CURRENT BALANCE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '\$ 13 357,50',
                          style: TextStyle(
                            color: textLight,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Incomes & Expenses Split
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryColumn(
                                'INCOMES',
                                '\$17,500',
                                Icons.arrow_upward,
                                incomeColor,
                              ),
                              _buildSummaryColumn(
                                'EXPENSES',
                                '-\$9 240,78',
                                Icons.arrow_downward,
                                expenseColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Carousel Indicator dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Transaction Items List
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildDateHeader('11 Sep 2018', '-\$86,35'),
                    _buildTransactionItem(
                      Icons.directions_bus,
                      Colors.amber,
                      'Transport',
                      'Bus tickets',
                      '-\$3,99',
                      expenseColor,
                    ),
                    _buildTransactionItem(
                      Icons.face,
                      Colors.redAccent,
                      'Haircut',
                      '',
                      '-\$25,00',
                      expenseColor,
                    ),
                    _buildTransactionItem(
                      Icons.videogame_asset,
                      Colors.purple,
                      'Fun',
                      'PS4 videogame',
                      '-\$32,99',
                      expenseColor,
                    ),
                    _buildTransactionItem(
                      Icons.local_gas_station,
                      Colors.blue,
                      'Gasoline',
                      '',
                      '-\$24,37',
                      expenseColor,
                    ),

                    const SizedBox(height: 15),
                    _buildDateHeader('12 Sep 2018', '\$6 236,87'),
                    _buildTransactionItem(
                      Icons.attach_money,
                      incomeColor,
                      'Salary',
                      '',
                      '+\$1 000,00',
                      incomeColor,
                    ),
                    _buildTransactionItem(
                      Icons.directions_car,
                      Colors.amber,
                      'Car',
                      '',
                      '-\$45,00',
                      expenseColor,
                    ),
                    const SizedBox(
                      height: 80,
                    ), // Space for floating bottom navigation bar
                  ]),
                ),
              ),
            ],
          ),

          // Custom Floating Bottom Navigation Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(Icons.list, 'Feed', purplePrimary, true),
                  _buildBottomNavItem(
                    Icons.pie_chart_outline,
                    'Charts',
                    Colors.grey,
                    false,
                  ),

                  // Center Floating Action Add Button
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: purplePrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  _buildBottomNavItem(
                    Icons.grid_view,
                    'Categories',
                    Colors.grey,
                    false,
                  ),
                  _buildBottomNavItem(
                    Icons.tune,
                    'Settings',
                    Colors.grey,
                    false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Component Builders
  Widget _buildMonthItem(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            )
          : null,
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(
    String title,
    String amount,
    IconData icon,
    Color tagColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateHeader(String date, String balance) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            balance,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    String amount,
    Color amountColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF6F6F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),

          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),

              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),

          const Spacer(),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    Color color,
    bool isActive,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// Custom Clipper to generate the bottom curve on the purple header container

// class CustomHeaderClipper extends CustomClipper {
//   @overridePath
//   getPath(Size size) {
//     Path path = Path();
//     path.lineTo(0, size.height - 40);
//     var firstControlPoint = Offset(size.width / 2, size.height);
//     var firstEndPoint = Offset(size.width, size.height - 40);
//     path.quadraticBezierTo(
//       firstControlPoint.dx,
//       firstControlPoint.dy,
//       firstEndPoint.dx,
//       firstEndPoint.dy,
//     );
//     path.lineTo(size.width, 0);
//     path.close();
//     return path;
//   }

//   @overridebool
//   shouldReclip(CustomClipper oldClipper) => false;
// }
