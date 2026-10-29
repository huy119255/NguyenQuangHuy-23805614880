import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'screens/translator_screen.dart';

const String _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
final String apiBaseUrl =
    _configuredApiBaseUrl.isEmpty ||
        _configuredApiBaseUrl == 'https://your-deployed-api.example.com'
    ? 'http://10.0.2.2:5293'
    : _configuredApiBaseUrl;

void main() => runApp(const ChamCongApp());

class ChamCongApp extends StatelessWidget {
  const ChamCongApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chấm công Nhóm 6',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1769AA)),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: const LoginScreen(),
  );
}

class ApiService {
  static Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final uri = Uri.parse('$apiBaseUrl$path');
    final response = switch (method) {
      'GET' => await http.get(uri, headers: headers),
      'POST' => await http.post(uri, headers: headers, body: jsonEncode(body)),
      'PUT' => await http.put(uri, headers: headers, body: jsonEncode(body)),
      'PATCH' => await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ),
      'DELETE' => await http.delete(uri, headers: headers),
      _ => throw Exception('Phương thức API không hợp lệ.'),
    };
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? data['message'] : null;
      throw Exception(
        message?.toString() ?? 'API lỗi HTTP ${response.statusCode}.',
      );
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async => await request(
    'POST',
    '/api/auth/login',
    body: {'email': email, 'password': password},
  );
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String code,
  ) async => await request(
    'POST',
    '/api/auth/verify-login-otp',
    body: {'email': email, 'code': code},
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool hidden = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _message('Vui lòng nhập email và mật khẩu.');
      return;
    }
    setState(() => loading = true);
    try {
      await ApiService.login(email.text.trim(), password.text);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(email: email.text.trim())),
      );
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FB),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 78,
                  color: Color(0xFF1769AA),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CHẤM CÔNG NHÓM 6',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Chấm công nhanh, minh bạch, đúng vị trí'),
                const SizedBox(height: 32),
                TextField(
                  controller: email,
                  enabled: !loading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  enabled: !loading,
                  obscureText: hidden,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => hidden = !hidden),
                      icon: Icon(
                        hidden ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: loading ? null : signIn,
                    icon: const Icon(Icons.login),
                    label: Padding(
                      padding: const EdgeInsets.all(12),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('ĐĂNG NHẬP'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Xác thực hai bước bằng Gmail OTP',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final code = TextEditingController();
  bool loading = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> verify() async {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code.text.trim())) {
      _message('OTP phải gồm đúng 6 chữ số.');
      return;
    }
    setState(() => loading = true);
    try {
      final result = await ApiService.verifyOtp(widget.email, code.text.trim());
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            role: (result['role'] ?? 'Customer').toString(),
            fullName: (result['fullName'] ?? widget.email).toString(),
            token: (result['accessToken'] ?? '').toString(),
          ),
        ),
        (_) => false,
      );
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Xác thực Gmail OTP')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 76,
                color: Color(0xFF1769AA),
              ),
              const SizedBox(height: 20),
              const Text(
                'XÁC THỰC ĐĂNG NHẬP',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Mã OTP đã gửi đến ${widget.email}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: code,
                autofocus: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mã OTP 6 số',
                  prefixIcon: Icon(Icons.password),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading ? null : verify,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('XÁC NHẬN OTP'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DashboardScreen extends StatelessWidget {
  final String role, fullName, token;
  const DashboardScreen({
    super.key,
    required this.role,
    required this.fullName,
    required this.token,
  });
  @override
  Widget build(BuildContext context) {
    final normalized = role.toLowerCase();
    return normalized == 'admin'
        ? AdminDashboard(name: fullName, token: token)
        : normalized == 'employee'
        ? EmployeeDashboard(name: fullName, token: token)
        : CustomerDashboard(name: fullName);
  }
}

class Shell extends StatelessWidget {
  final String title, name;
  final Widget child;
  const Shell({
    super.key,
    required this.title,
    required this.name,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [
        IconButton(
          tooltip: 'Dịch realtime',
          icon: const Icon(Icons.translate),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TranslatorScreen()),
            );
          },
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Xin chào, $name',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}

class AdminDashboard extends StatefulWidget {
  final String name, token;
  const AdminDashboard({super.key, required this.name, required this.token});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Future<List<dynamic>> load() async =>
      await ApiService.request('GET', '/api/employees', token: widget.token)
          as List<dynamic>;
  Future<void> createEmployee() async {
    final form = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const EmployeeForm(),
    );
    if (form == null) return;
    try {
      await ApiService.request(
        'POST',
        '/api/employees',
        body: form,
        token: widget.token,
      );
      setState(() {});
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> editEmployee(Map<String, dynamic> item) async {
    final form = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EmployeeForm(initial: item),
    );
    if (form == null) return;
    try {
      await ApiService.request(
        'PUT',
        '/api/employees/${item['id']}',
        body: form,
        token: widget.token,
      );
      setState(() {});
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> deleteEmployee(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vô hiệu hóa nhân viên?'),
        content: Text(
          'Tài khoản ${item['fullName']} sẽ không bị xóa lịch sử chấm công.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.request(
        'DELETE',
        '/api/employees/${item['id']}',
        token: widget.token,
      );
      setState(() {});
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) => Shell(
    title: 'Quản trị hệ thống',
    name: widget.name,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Danh sách nhân viên',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: createEmployee,
              icon: const Icon(Icons.person_add),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Không tải được dữ liệu: ${snapshot.error}');
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) return const Text('Chưa có nhân viên.');
            return Column(
              children: rows
                  .map(
                    (item) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            item['employeeCode'].toString().substring(0, 1),
                          ),
                        ),
                        title: Text(item['fullName'].toString()),
                        subtitle: Text(
                          '${item['employeeCode']} • ${item['department'] ?? 'Chưa có phòng ban'}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') editEmployee(item);
                            if (action == 'delete') deleteEmployee(item);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Sửa thông tin'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Vô hiệu hóa'),
                            ),
                          ],
                          icon: Icon(
                            item['isActive'] == true
                                ? Icons.check_circle
                                : Icons.pause_circle,
                            color: item['isActive'] == true
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

class EmployeeForm extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const EmployeeForm({super.key, this.initial});
  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      code = TextEditingController(),
      department = TextEditingController(),
      position = TextEditingController();
  bool isActive = true;

  bool get isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    if (item != null) {
      name.text = item['fullName']?.toString() ?? '';
      code.text = item['employeeCode']?.toString() ?? '';
      department.text = item['department']?.toString() ?? '';
      position.text = item['position']?.toString() ?? '';
      isActive = item['isActive'] == true;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      email,
      password,
      code,
      department,
      position,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(isEditing ? 'Sửa nhân viên' : 'Thêm nhân viên'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Họ tên'),
          ),
          if (!isEditing) ...[
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
          ],
          TextField(
            controller: code,
            decoration: const InputDecoration(labelText: 'Mã nhân viên'),
          ),
          TextField(
            controller: department,
            decoration: const InputDecoration(labelText: 'Phòng ban'),
          ),
          TextField(
            controller: position,
            decoration: const InputDecoration(labelText: 'Chức vụ'),
          ),
          if (isEditing)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đang hoạt động'),
              value: isActive,
              onChanged: (value) => setState(() => isActive = value),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, {
          'fullName': name.text.trim(),
          'employeeCode': code.text.trim(),
          'department': department.text.trim(),
          'position': position.text.trim(),
          if (isEditing) 'isActive': isActive,
          if (!isEditing) ...{
            'email': email.text.trim(),
            'password': password.text,
          },
        }),
        child: const Text('Lưu'),
      ),
    ],
  );
}

class EmployeeDashboard extends StatefulWidget {
  final String name, token;
  const EmployeeDashboard({super.key, required this.name, required this.token});
  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int? attendanceId;
  bool loading = false;
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Vui lòng bật dịch vụ vị trí trên thiết bị.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Ứng dụng cần quyền vị trí để chấm công.');
    }
    return Geolocator.getCurrentPosition();
  }

  Future<String?> scanQrCode() => Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
  );
  Future<void> toggleAttendance({String method = 'GPS'}) async {
    setState(() => loading = true);
    try {
      if (attendanceId == null) {
        final position = await getCurrentPosition();
        final result = await ApiService.request(
          'POST',
          '/api/attendance/check-in',
          token: widget.token,
          body: {
            'method': method,
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
        );
        attendanceId = result['id'] as int;
      } else {
        await ApiService.request(
          'PATCH',
          '/api/attendance/$attendanceId/check-out',
          token: widget.token,
        );
        attendanceId = null;
      }
      setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Shell(
    title: 'Dashboard nhân viên',
    name: widget.name,
    child: Column(
      children: [
        Card(
          color: const Color(0xFFE8F1FA),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  attendanceId == null ? Icons.location_on : Icons.timer,
                  size: 56,
                  color: const Color(0xFF1769AA),
                ),
                const SizedBox(height: 12),
                Text(
                  attendanceId == null
                      ? 'Bạn chưa bắt đầu ca làm'
                      : 'Ca làm đang hoạt động',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: loading ? null : () => toggleAttendance(),
                    icon: Icon(
                      attendanceId == null ? Icons.login : Icons.logout,
                    ),
                    label: Text(
                      attendanceId == null ? 'CHECK-IN VỚI GPS' : 'CHECK-OUT',
                    ),
                  ),
                ),
                if (attendanceId == null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () async {
                              final qr = await scanQrCode();
                              if (qr != null &&
                                  qr.isNotEmpty &&
                                  context.mounted) {
                                await toggleAttendance(method: 'QR');
                              }
                            },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('CHECK-IN BẰNG QR'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F1FA),
              child: Icon(Icons.translate, color: Color(0xFF1769AA)),
            ),
            title: const Text(
              'Dịch Realtime',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Dịch văn bản, giọng nói và ảnh nhanh chóng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TranslatorScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.verified_user, color: Colors.green),
          title: Text('Chấm công có xác thực'),
          subtitle: Text(
            'Mỗi lượt chấm công được ghi nhận kèm phương thức và vị trí.',
          ),
        ),
      ],
    ),
  );
}

class CustomerDashboard extends StatelessWidget {
  final String name;
  const CustomerDashboard({super.key, required this.name});
  @override
  Widget build(BuildContext context) => Shell(
    title: 'Khu vực khách hàng',
    name: name,
    child: const Card(
      child: ListTile(
        leading: Icon(Icons.support_agent, color: Color(0xFF1769AA), size: 34),
        title: Text('Xin chào quý khách'),
        subtitle: Text('Đây là khu vực dành cho tài khoản khách hàng.'),
      ),
    ),
  );
}

class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quét mã QR chấm công')),
    body: MobileScanner(
      onDetect: (capture) {
        final value = capture.barcodes.isEmpty
            ? null
            : capture.barcodes.first.rawValue;
        if (value != null && value.isNotEmpty) Navigator.pop(context, value);
      },
    ),
  );
}
