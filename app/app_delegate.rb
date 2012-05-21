class AppDelegate
  attr_reader :navigation_controller

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = self.navigation_controller
    @window.rootViewController.wantsFullScreenLayout = true
    @window.makeKeyAndVisible
    true
  end

  def navigation_controller
    @navigation_controller ||= UINavigationController.alloc.init
  end
end
