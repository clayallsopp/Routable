# Routable
A UIViewController->URL router.

```ruby
  @router.map("profile/:id", ProfileController)

  # Later on...

  # Pushes a ProfileController with .initWithParams(:id => 189)
  @router.open("profile/189")
```

Why is this awesome? Because now you can push any view controller from any part of the app with just a string: buttons, push notifications, anything.

## Installation

```ruby
gem install routable
```

And now in your Rakefile, require `routable`:

```ruby
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'
require 'routable'

Motion::Project::App.setup do |app|
  ...
end
```

## Setup

For every UIViewController you want routable with `:symbolic` params, you need to define `.initWithParams({})`.

```ruby
class ProfileController < UIViewController
  attr_accessor :user_id

  def initWithParams(params = {})
    init()
    self.user_id = params[:user_id]
    self
  end
end
```

Here's an example of how you could setup Routable for the entire application:

```ruby
class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.makeKeyAndVisible

    # Make our URLs
    map_urls

    # .open(url, animated)
    if User.logged_in_user
      @router.open("menu", false)
    else
      @router.open("login", false)
    end

    true
  end

  def map_urls
    @router = Routable::Router.router
    @router.navigation_controller = UINavigationController.alloc.init

    # :modal means we push it modally.
    @router.map("login", LoginController, modal: true)

    # :shared means it will only keep one instance of this VC in the hierarchy;
    # if we push it again later, it will pop any covering VCs.
    @router.map("menu", MenuController, shared: true)
    @router.map("profile/:id", ProfileController)

    # :resets will reset the navigation stack with the target view controller
    @router.map("messages", MessagesController, resets: true)
    @router.map("message/:id", MessageThreadController)

    # can also route arbitrary blocks of code
    @router.map("logout") do
      User.logout
    end
    @router.map("logout/:id") do |params|
      User.logout(params[:id])
    end

    @window.rootViewController = @router.navigation_controller
  end
end
```

## Configuration of View Controllers

If you need to configure a view controller before the router navigates to it, use a block:

``` ruby
# Configure and push an ImageEditorController
BW::Device.camera.any.picture(media_types: [:movie, :image]) do |result|
  router.open('editor') do |controller|
    controller.image = result[:original_image]
  end
end
```
