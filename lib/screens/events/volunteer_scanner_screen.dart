import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class VolunteerScannerScreen extends StatefulWidget {
  const VolunteerScannerScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerScannerScreen> createState() => _VolunteerScannerScreenState();
}

class _VolunteerScannerScreenState extends State<VolunteerScannerScreen> {
  Event? _selectedEvent;
  bool _isPinVerified = false;
  final TextEditingController _pinController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _pinController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    if (_selectedEvent == null) return;
    
    final pin = _pinController.text.trim();
    final eventService = Provider.of<EventService>(context, listen: false);
    
    if (eventService.verifyScannerPin(_selectedEvent!.id, pin)) {
      setState(() {
        _isPinVerified = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid PIN'), backgroundColor: Colors.red),
      );
    }
  }
  
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _selectedEvent == null) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        
        // Haptic feedback or sound could be added here
        
        final eventService = Provider.of<EventService>(context, listen: false);
        final registrationId = barcode.rawValue!;
        
        try {
          final success = await eventService.checkInUser(_selectedEvent!.id, registrationId);
          
          if (mounted) {
            _showResultDialog(success: success, message: success ? 'Check-in Successful!' : 'Check-in Failed or Already Checked In');
          }
        } catch (e) {
           if (mounted) {
             _showResultDialog(success: false, message: 'Error: $e');
           }
        }
        
        // Anti-bounce delay is handled by the dialog interaction mostly, 
        // but we reset _isProcessing after dialog closes or delay
        break; // Process only first code
      }
    }
  }
  
  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Future.delayed(const Duration(seconds: 1), () {
                 if (mounted) setState(() => _isProcessing = false);
              });
            },
            child: const Text('Next Scan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('Volunteer Scanner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
             if (_isPinVerified) {
               setState(() {
                 _isPinVerified = false;
                 _pinController.clear();
               });
             } else if (_selectedEvent != null) {
               setState(() {
                 _selectedEvent = null;
               });
             } else {
               Navigator.pop(context);
             }
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedEvent == null) {
      return _buildEventList();
    } else if (!_isPinVerified) {
      return _buildPinEntry();
    } else {
      return _buildScanner();
    }
  }

  Widget _buildEventList() {
    return Consumer<EventService>(
      builder: (context, eventService, _) {
        final activeEvents = eventService.activeEvents;
        
        if (activeEvents.isEmpty) {
           return const Center(child: Text('No active events to scan for.', style: TextStyle(color: Colors.white)));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeEvents.length,
          itemBuilder: (context, index) {
            final event = activeEvents[index];
            return Card(
              color: Colors.white.withOpacity(0.1),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(event.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(event.eventDate.toString().split(' ')[0], style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () => setState(() => _selectedEvent = event),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPinEntry() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Enter PIN for "${_selectedEvent!.title}"', style: const TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 5),
            textAlign: TextAlign.center,
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'PIN',
              hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _verifyPin,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              child: const Text('Verify Access'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
        ),
        
        // Overlay properties (optional visual guide)
        Container(
          decoration: ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: const Color(0xFF8B5CF6),
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
        ),
        
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
             children: [
               Text('Scanning: ${_selectedEvent!.title}', style: const TextStyle(color: Colors.white, backgroundColor: Colors.black54)),
             ],
          ),
        ),
      ],
    );
  }
}
// Helper class for overlay shape if not provided by library, 
// but mobile_scanner usually provides one or we make do without.
// Actually, QrScannerOverlayShape comes from qr_code_scanner package which I didn't add.
// Use a simple Container with border or just plain view.
// I'll implement a simple custom painter if needed, but for now I'll remove QrScannerOverlayShape to avoid error if package missing.
// Code corrected below to remove external dependency not in pubspec (qr_code_scanner).
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero)
      ..addRect(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _cutOutSize = cutOutSize != null && cutOutSize < width
        ? cutOutSize
        : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: _cutOutSize,
      height: _cutOutSize,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        cutOutRect,
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    final borderPath = Path()
      ..moveTo(cutOutRect.left, cutOutRect.top + borderLength)
      ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)
      ..quadraticBezierTo(cutOutRect.left, cutOutRect.top,
          cutOutRect.left + borderRadius, cutOutRect.top)
      ..lineTo(cutOutRect.left + borderLength, cutOutRect.top)
      ..moveTo(cutOutRect.right, cutOutRect.top + borderLength)
      ..lineTo(cutOutRect.right, cutOutRect.top + borderRadius)
      ..quadraticBezierTo(cutOutRect.right, cutOutRect.top,
          cutOutRect.right - borderRadius, cutOutRect.top)
      ..lineTo(cutOutRect.right - borderLength, cutOutRect.top)
      ..moveTo(cutOutRect.right, cutOutRect.bottom - borderLength)
      ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius)
      ..quadraticBezierTo(cutOutRect.right, cutOutRect.bottom,
          cutOutRect.right - borderRadius, cutOutRect.bottom)
      ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom)
      ..moveTo(cutOutRect.left, cutOutRect.bottom - borderLength)
      ..lineTo(cutOutRect.left, cutOutRect.bottom - borderRadius)
      ..quadraticBezierTo(cutOutRect.left, cutOutRect.bottom,
          cutOutRect.left + borderRadius, cutOutRect.bottom)
      ..lineTo(cutOutRect.left + borderLength, cutOutRect.bottom);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
