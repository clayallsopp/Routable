module Routable

  class RouteNotFound < Exception; end

  class Router
    TRANSITION_STYLES = {
      :cover => UIModalTransitionStyleCoverVertical,
      :flip => UIModalTransitionStyleFlipHorizontal,
      :dissolve => UIModalTransitionStyleCrossDissolve,
      :curl => UIModalTransitionStylePartialCurl
    }

    PRESENTATION_STYLES = {
      :full_screen => UIModalPresentationFullScreen,
      :page_sheet => UIModalPresentationPageSheet,
      :form_sheet => UIModalPresentationFormSheet,
      :current => UIModalPresentationCurrentContext
    }

    # Singleton, for practical use (you might not want)
    # to have more than one router.
    class << self
      def router
        @router ||= Router.new
      end
    end

    # The root UINavigationController we use to push/pop view controllers
    attr_accessor :navigation_controller

    # Hash of URL => UIViewController classes
    # EX
    # {"users/:id" => UsersController,
    #  "users/:id/posts" => PostsController,
    #  "users/:user_id/posts/:id" => PostController }
    def routes
      @routes ||= {}
    end

    # Map a URL to a UIViewController
    # EX
    # router.map "/users/:id", UsersController
    # PARAMS
    #   url => the URL to map
    #   klass (optional) => the UIViewController class to open
    #   options (optional) => hash of options
    #   &callback => the block to be run when opening the URL
    # OPTIONS
    #   :modal => true/false
    #     - We present the VC modally (router is not shared between the new nav VC)
    #   :shared => true/false
    #     - If URL is called again, we pop to that VC if it's in memory.
    #   :resets => true/false
    #     - Resets the navigation stack with the target view controller
    #   :transition => [:cover, :flip, :dissolve, :curl]
    #     - A symbol to represented transition style used. Mapped to UIModalTransitionStyle.
    #   :presentation => [:full_screen, :page_sheet, :form_sheet, :current]
    #     - A symbol to represented presentation style used. Mapped to UIModalPresentationStyle.
    def map(url, klass = nil, options = {}, &callback)
      format = url

      if callback
        self.routes[format] = options.merge!(callback: callback)
      end

      if options[:transition] && !TRANSITION_STYLES.keys.include?(options[:transition])
        raise ArgumentError, ":transition must be one of #{TRANSITION_STYLES.keys}"
      end

      if options[:presentation] && !PRESENTATION_STYLES.keys.include?(options[:presentation])
        raise ArgumentError, ":presentation must be one of #{PRESENTATION_STYLES.keys}"
      end

      self.routes[format] = options.merge!(klass: klass)
    end

    # Open the given URL via the iOS protocol
    # EX
    # router.open_external("http://google.com")
    # => Opens Google in Safari.app
    def open_external(url)
      UIApplication.sharedApplication.openURL(NSURL.URLWithString(url))
    end

    # Push the UIViewController for the given url
    # EX
    # router.open("users/3")
    # => router.navigation_controller pushes a UsersController
    def open(url, animated = true, &block)
      if self.routes.exclude? url
        raise RouteNotFound, "No route found for URL '#{url}'"
      end

      controller_options = options_for_url(url)

      if controller_options[:callback]
        params = controller_options[:open_params]
        callback = controller_options[:callback]
        case callback.arity
        when 0
          callback.call
        when 1
          callback.call(params)
        end
        return
      end

      controller = controller_for_url(url)

      # Allow configuration of the view controller after
      # initialization but before navigating to the view controller
      if block_given?
        block.call(controller)
      end

      if self.navigation_controller.modalViewController
        dismiss_animated = animated

        # Can't dismiss and present two controllers animated at the same time,
        # so we just dismiss the current one without an animation
        if controller_options[:modal] && dismiss_animated
          dismiss_animated = false
        end

        self.navigation_controller.dismissModalViewControllerAnimated(dismiss_animated)
      end

      if controller_options[:resets]
        navigation_controller.setViewControllers([controller], animated: animated)
      elsif controller_options[:modal]
        if controller.class == UINavigationController
          self.navigation_controller.presentModalViewController(controller, animated: animated)
        else
          tempNavigationController = UINavigationController.alloc.init
          tempNavigationController.pushViewController(controller, animated: false)
          tempNavigationController.modalTransitionStyle = controller.modalTransitionStyle
          tempNavigationController.modalPresentationStyle = controller.modalPresentationStyle
          self.navigation_controller.presentModalViewController(tempNavigationController, animated: animated)
        end
      else
        if self.navigation_controller.viewControllers.member? controller
          self.navigation_controller.popToViewController(controller, animated:animated)
        else
          self.navigation_controller.pushViewController(controller, animated:animated)
        end
      end
    end

    # Pop the top level UIViewController
    # EX
    # router.pop
    def pop(animated = true)
      if self.navigation_controller.modalViewController
        self.navigation_controller.dismissModalViewControllerAnimated(animated)
      else
        self.navigation_controller.popViewControllerAnimated(animated)
      end
    end

    def options_for_url(url)
      # map of url => options

      @url_options_cache ||= {}
      if @url_options_cache[url]
        return @url_options_cache[url]
      end

      parts = url.split("/")

      open_options = nil
      open_params = {}

      self.routes.each { |format, options|

        # If the # of path components isn't the same, then
        # it for sure isn't a match.
        format_parts = format.split("/")
        if format_parts.count != parts.count
          next
        end

        matched = true
        format_params = {}
        # go through each of the path compoenents and
        # check if they match up (symbols aside)
        format_parts.each_with_index {|format_part, index|
          check_part = parts[index]

          # if we're looking at a symbol (ie :user_id),
          # then note it and move on.
          if format_part[0] == ":"
            format_params[format_part[1..-1].to_sym] = check_part
            next
          end

          # if we're looking at normal strings,
          # check equality.
          if format_part != check_part
            matched = false
            break
          end
        }

        if !matched
          next
        end

        open_options = options
        open_params = format_params
      }

      @url_options_cache[url] = open_options.merge(open_params: open_params)
    end

    # Returns a UIViewController for the given url
    # EX
    # router.controller_for_url("users/3")
    # => #<UsersController @id='3'>
    def controller_for_url(url)
      return shared_vc_cache[url] if shared_vc_cache[url]

      open_options = options_for_url(url)
      open_params = open_options[:open_params]
      open_klass = open_options[:klass]
      controller = open_klass.alloc
      if controller.respond_to? :initWithParams
        controller = controller.initWithParams(open_params)
      else
        controller = controller.init
      end

      if open_options[:shared]
        shared_vc_cache[url] = controller
        # when controller.viewDidUnload called, remove from cache.
        controller.class.class_eval do
          define_method(:new_dealloc) do
            shared_vc_cache.delete url
          end
        end
        controller.instance_eval do
          def viewDidUnload
            new_dealloc
            super
          end
        end
      end

      transition = open_options[:transition]
      if transition
        controller.modalTransitionStyle = TRANSITION_STYLES[transition]
      end

      presentation = open_options[:presentation]
      if presentation
        controller.modalPresentationStyle = PRESENTATION_STYLES[presentation]
      end

      controller
    end

    def shared_vc_cache
      @shared_vc_cache ||= {}
    end
  end
end
