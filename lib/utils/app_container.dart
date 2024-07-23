import 'package:get_it/get_it.dart';

class AppContainer {
  AppContainer register<T extends Object>(T dep) {
    GetIt.instance.registerSingleton<T>(dep);

    return this;
  }

  T get<T extends Object>() {
    return GetIt.instance.get<T>();
  }
}

final appContainer = AppContainer();
