import 'package:alouette_lib_trans/alouette_lib_trans.dart' as trans_lib;

/// 自动配置服务，负责应用启动时的自动连接和配置 - 使用 alouette-lib-trans 库
class AutoConfigService {
  final trans_lib.LLMConfigService _llmConfigService = trans_lib.LLMConfigService();

  /// 自动配置LLM连接
  Future<trans_lib.LLMConfig?> autoConfigureLLM() async {
    return await _llmConfigService.autoDetectConfig();
  }
}
