import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:oboa_chat_app/core/routing/router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/di_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('ko_KR');
    Intl.defaultLocale = 'ko_KR';
  } catch (e) {
    print('2.2. intl 초기화 중 에러 발생: $e');
    rethrow;
  }

  // Load environment variables
  await dotenv.load(fileName: "assets/config/.env");

  // 수파베이스
  print("dotenv.env['SUPABASE_URL'] : ${dotenv.env['SUPABASE_URL']}");
  print("dotenv.env['SUPABASE_ANON_KEY'] : ${dotenv.env['SUPABASE_ANON_KEY']}");
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  try {
    if (Supabase.instance.client.auth.currentUser == null) {
      // 현재 로그인된 사용자가 없으면 익명 로그인 시도
      final AuthResponse response = await Supabase.instance.client.auth.signInAnonymously();
      print('response: ${response}');
      if (response.user != null) {
        print('익명 사용자 로그인 성공: ${response.user!.id}');
      } else {
        print('익명 사용자 로그인 실패: ${response.user}');
      }
    } else {
      print('이미 로그인된 사용자: ${Supabase.instance.client.auth.currentUser!.id}');
    }
  } catch (e) {
    print('익명 사용자 로그인 중 에러 발생: $e');
    // 네트워크 문제 등 익명 로그인 실패 시 에러 처리
  }

  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!,
  );

  diSetup(isTesting: false);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
    );
  }
}
