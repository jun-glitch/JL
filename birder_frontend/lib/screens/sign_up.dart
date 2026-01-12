// TODO: 아이디 중복 확인
// TODO: 이메일 인증 추가 필요


import 'package:birder_frontend/services/auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SignupStepperPage extends StatefulWidget {
  const SignupStepperPage({super.key});

  @override
  State<SignupStepperPage> createState() => _SignupStepperPageState();
}

class _SignupStepperPageState extends State<SignupStepperPage> {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:8000', // 안드로이드 에뮬레이터 기준
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final auth = AuthApi('http://10.0.2.2:8000');
  // 에뮬레이터면 10.0.2.2
  // 실폰이면 http://내PC_IP:8000 또는 배포 도메인

  Future<void> _submit() async {
    final payload = {
      "username": _idCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "password": _pwCtrl.text,
      "name": _nameCtrl.text.trim(),
      "agreeTerms": _agreeTerms,
      "agreePrivacy": _agreePrivacy,
    };

    try {
      await _dio.post('/api/auth/signup/', data: payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가입 완료!')),
      );
      Navigator.pop(context); // 로그인 화면으로
    } on DioException catch (e) {
      String msg = '가입 실패';

      final data = e.response?.data;
      if (data is Map) {
        if (data["detail"] != null) msg = data["detail"].toString();
        else if (data["message"] != null) msg = data["message"].toString();
        else if (data["username"] != null) msg = data["username"].toString();
        else if (data["email"] != null) msg = data["email"].toString();
        else msg = data.toString();
      } else if (data != null) {
        msg = data.toString();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류')),
      );
    }
  }

  int _currentStep = 0;

  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());

  // 컨트롤러
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  // 완료 상태 표시용
  final List<bool> _completed = [false, false, false];

  bool get _isLastStep => _currentStep == 2;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    final formState = _formKeys[_currentStep].currentState;
    final isValid = formState?.validate() ?? false;

    // 3단계는 validate + 약관체크까지해야 제출
    if (_currentStep == 2) {
      if (!_agreeTerms || !_agreePrivacy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필수 약관에 동의해 주세요.')),
        );
        return;
      }
    }

    if (!isValid) return;

    setState(() {
      _completed[_currentStep] = true;

      if (_isLastStep) {
        _submit();
      } else {
        _currentStep += 1;
      }
    });
  }

  void _goBack() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
  }


  StepState _stepState(int index) {
    if (_completed[index]) return StepState.complete;
    if (_currentStep == index) return StepState.editing;
    return StepState.indexed;
  }


  @override
  Widget build(BuildContext context) {
    const sky = Color(0xFFDCEBFF);
    return Scaffold(
      backgroundColor: sky,
      appBar: AppBar(
          backgroundColor: sky,
          title: const Text('회원가입')
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _goNext,
        onStepCancel: _goBack,
        onStepTapped: (i) => setState(() => _currentStep = i),
        controlsBuilder: (context, details) {
          // 버튼
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_isLastStep ? '가입하기' : '다음'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _currentStep == 0 ? null : details.onStepCancel,
                  child: const Text('이전'),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('계정 정보'),
            isActive: _currentStep >= 0,
            state: _stepState(0),
            content: Form(
              key: _formKeys[0],
              child: Column(
                children: [
                  TextFormField(
                    controller: _idCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '아이디',
                      hintText: '6자리 이상으로 입력해주세요',
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return '아이디를 입력해 주세요.';

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pwCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      hintText: '8자 이상',
                    ),
                    validator: (v) {
                      final value = v ?? '';
                      if (value.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pwConfirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 확인',
                    ),
                    validator: (v) {
                      if ((v ?? '') != _pwCtrl.text) return '비밀번호가 일치하지 않습니다.';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('프로필 정보'),
            isActive: _currentStep >= 1,
            state: _stepState(1),
            content: Form(
              key: _formKeys[1],
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: '이름'),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return '이름을 입력해 주세요.';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      hintText: 'name@example.com',
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return '이메일을 입력해 주세요.';
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(value)) return '이메일 형식이 올바르지 않습니다.';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('약관 동의'),
            isActive: _currentStep >= 2,
            state: _stepState(2),
            content: Form(
              key: _formKeys[2],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('(필수) 이용약관 동의'),
                    value: _agreeTerms,
                    onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('(필수) 개인정보 처리방침 동의'),
                    value: _agreePrivacy,
                    onChanged: (v) => setState(() => _agreePrivacy = v ?? false),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '※ 필수 항목에 모두 동의해야 가입할 수 있어요.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
