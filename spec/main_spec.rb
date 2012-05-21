class UsersTestController < UIViewController
  attr_accessor :user_id

  def initWithParams(params = {})
    init()
    self.user_id = params[:user_id]
    self
  end
end

class NoParamsController < UIViewController
end

describe "the url router" do
  before do
    @router = Routable::Router.new

    @nav_controller = UINavigationController.alloc.init
    @nav_controller.setViewControllers([], animated: false)
    @nav_controller.viewControllers.count.should == 0
  end

  def make_test_controller_route
    format = "users/:user_id"
    @router.map(format, UsersTestController)
    @router.routes.should == {format => {:klass => UsersTestController}}
  end

  it "maps the correct urls" do
    make_test_controller_route

    user_id = "1001"
    controller = @router.controller_for_url("users/#{user_id}")
    controller.class.should == UsersTestController
    controller.user_id.should == user_id
  end

  it "opens urls with no params" do
    @router.navigation_controller = @nav_controller
    @router.map("url", NoParamsController)
    @router.open("url")
    @router.navigation_controller.viewControllers.count.should == 1
  end

  it "opens nav controller to url" do
    @router.navigation_controller = @nav_controller
    make_test_controller_route
    @router.open("users/3")

    @nav_controller.viewControllers.count.should == 1
    @nav_controller.viewControllers.last.class.should == UsersTestController    
  end

  it "uses the shared properties correctly" do
    shared_format = "users"
    format= "users/:user_id"

    @router.map(format, UsersTestController)
    @router.map(shared_format, UsersTestController, shared: true)
    @router.navigation_controller = @nav_controller
    @router.open("users/3")
    @router.open("users/4")
    @router.open("users")
    @router.open("users/5")

    @nav_controller.viewControllers.count.should == 4

    @router.open("users")
    @nav_controller.viewControllers.count.should == 3
  end
end