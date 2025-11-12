import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'NEWS_API_KEY')
  static final String newsApiKey = _Env.newsApiKey;
}
