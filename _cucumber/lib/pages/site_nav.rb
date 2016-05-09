require_relative 'base'

class SiteNav < Base

  HEADER                       =  { css: '.header-wrap' }
  LOGIN_LINK                   =  { css: '.login' }
  LOGOUT_LINK                  =  { css: '.logout' }
  REGISTER_LINK                =  { css: '.register' }
  LOGGED_IN                    =  { css: '.logged-in' }
  LOGGED_IN_NAME               =  { css: '.logged-in-name' }
  MOBILE_MENU                  =  { css: '.nav-toggle' }
  MOBILE_MENU_OPEN             =  { css: '.nav-open' }
  TOPICS                       =  { xpath: "//nav[@class='mega-menu']//ul/li/*[contains(text(),'Topics')]" }
  TECHNOLOGIES                 =  { xpath: "//nav[@class='mega-menu']//ul/li/*[contains(text(),'Technologies')]" }
  COMMUNITY                    =  { xpath: "//nav[@class='mega-menu']//ul/li/*[contains(text(),'Community')]" }
  RESOURCES                    =  { xpath: "//nav[@class='mega-menu']//ul/li/*[contains(text(),'Resources')]" }
  DOWNLOADS                    =  { xpath: "//nav[@class='mega-menu']//ul/li/*[contains(text(),'Downloads')]" }
  TOPICS_SUB_NAV               =  { xpath: '//*[@id="sub-nav-topics"]' }
  TECHNOLOGIES_SUB_NAV         =  { xpath: '//*[@id="sub-nav-technologies"]' }
  COMMUNITY_SUB_NAV            =  { xpath: '//*[@id="sub-nav-community"]' }
  SUB_NAV_OPEN                 =  { css: '.sub-nav-open' }

  def initialize(driver)
    super
  end

  def logged_in?
    wait_for(12) { displayed?(LOGGED_IN) && displayed?(LOGGED_IN_NAME) && text_of(LOGGED_IN_NAME) != '' }
    text_of(LOGGED_IN_NAME)
  end

  def logged_out?
    wait_for(12) { displayed?(LOGIN_LINK) }
    displayed?(REGISTER_LINK)
  end

  def click_login
    click_on(LOGIN_LINK)
  end

  def click_logout
    click_on(LOGOUT_LINK)
    wait_for_ajax
  end

  def click_register
    click_on(REGISTER_LINK)
  end

  def toggle_menu
    click_on(MOBILE_MENU)
    wait_for { displayed?(MOBILE_MENU_OPEN) }
  end

  def toggle_menu_and_tap(menu_item)
    click_on(MOBILE_MENU)
    wait_for { displayed?(MOBILE_MENU_OPEN) }
    click_on_nav_menu(menu_item)
  end

  def navigate_to(link)
    visit
    wait_for_ajax
    if text_of(MOBILE_MENU).include?('MENU')
      click_on(MOBILE_MENU)
      wait_for { displayed?(MOBILE_MENU_OPEN) }
      click_on(LOGIN_LINK) if link == 'login'
      click_on(REGISTER_LINK) if link == 'register'
    else
      click_on(LOGIN_LINK) if link == 'login'
      click_on(REGISTER_LINK) if link == 'register'
    end
  end

  def click_on_nav_menu(menu_item)
    case menu_item
      when 'login'
        el = LOGIN_LINK
      when 'register'
        el = REGISTER_LINK
      when 'topics'
        el = TOPICS
      when 'technologies'
        el = TECHNOLOGIES
      when 'community'
        el = COMMUNITY
      when 'resources'
        el = RESOURCES
      when 'downloads'
        el = DOWNLOADS
      else
        raise("#{menu_item} not recognised")
    end
    wait_for { displayed?(el) }
    click_on(el)
  end

  def hover_over_nav_menu(menu_item)
    case menu_item
      when 'topics'
        el = TOPICS
      when 'technologies'
        el = TECHNOLOGIES
      when 'community'
        el = COMMUNITY
      when 'resources'
        el = RESOURCES
      when 'downloads'
        el = DOWNLOADS
      else
        raise("#{menu_item} not recognised")
    end
    hover_on(el)
  end

  def menu_item_present?(menu_item)
    case menu_item
      when 'login'
        el = LOGIN_LINK
      when 'register'
        el = REGISTER_LINK
      when 'topics'
        el = TOPICS
      when 'technologies'
        el = TECHNOLOGIES
      when 'community'
        el = COMMUNITY
      when 'resources'
        el = RESOURCES
      when 'downloads'
        el = DOWNLOADS
      else
        raise("#{menu_item} not recognised")
    end
    displayed?(el)
  end

  def sub_menu_items(menu_item, resolution)
    case menu_item
      when 'topics'
        el = TOPICS_SUB_NAV
      when 'technologies'
        el = TECHNOLOGIES_SUB_NAV
      when 'community'
        el = COMMUNITY_SUB_NAV
      else
        raise("#{menu_item} not recognised")
    end
    wait_for { displayed?(SUB_NAV_OPEN) } if resolution == 'mobile'
    text_of(el)
  end

  def get_href_for(link)
    href = find(partial_link_text: link)
    href.attribute('href')
  end

end
