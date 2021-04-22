require 'puppeteer'
require 'pry-byebug'

class BotScript
  HEART = 'fr66n'
  USERNAME = 'e1e1d'
  LIKES = 'zV_Nj'
  COMMENTER_NAME = "ZIAjV"
  POST_BUTTON = 'y3zKF'
  COMMENT_INPUT = 'Ypffh'

  BLACKLIST = ['hotel, hostel', 'relax', 'travel', 'couple', 'stay', 'official']

  def self.run(hashtag, likes_thershold: 40, followers_thershold: 350, limit: 150, sleep_interval: 5)
    # Puppeteer.launch(headless: true, args: ['--user-data-dir=/Users/frydel/Library/Application Support/Google/Chrome','--profile-directory=Profile 1']) do |browser|
    Puppeteer.launch(headless: false, slow_mo: 120, args: ['--guest', '--window-size=1280,800']) do |browser|
      page = browser.pages.first || browser.new_page
      page.viewport = Puppeteer::Viewport.new(width: 1280, height: 800)

      page.goto('https://instagram.com/', wait_until: 'domcontentloaded')

      # Click 'Accept'
      page.wait_for_selector('.bIiDR')
      page.click('.bIiDR')

      # Enter username
      page.wait_for_selector('.pexuQ')
      page.Sx('//input').first.click
      page.keyboard.type_text('fabi.rydel')

      # Enter password
      page.Sx('//input').last.click
      page.keyboard.type_text('1shallpassIG!')

      # Login
      page.Sx('//button')[1].click

      sleep sleep_interval

      # Click search bar
      page.wait_for_selector('.wUAXj')
      page.click('.wUAXj')

      # Enter hashtag
      page.keyboard.type_text('#' + hashtag)
      page.wait_for_selector('._01UL2')
      page.SS('a.-qQT3').first.click
      page.keyboard.press('Enter')

      # Open first recent photo
      page.wait_for_selector('._bz0w')
      page.SS('div._bz0w')[9].click

      liked_users = []
      discarded_users = []
      done = 0

      while done < limit do
        begin
          page.wait_for_selector(".#{HEART}")

          # Next page, skip first one (who cares?)
          sleep sleep_interval
          page.SS('a.coreSpriteRightPaginationArrow').first.click
          sleep sleep_interval

          page.wait_for_selector(".#{USERNAME}")
          user_name = page.SS("div.#{USERNAME}").first.evaluate('el => el.textContent')

          if BLACKLIST.any? { |blacklisted| user_name.include? blacklisted }
            puts '-------------------------------'
            puts 'User is not interesting: ' + user_name.to_s
            next
          end

          if discarded_users.include?(user_name)
            puts '-------------------------------'
            puts 'User already discarded: ' + user_name.to_s
            next
          end

          if liked_users.include?(user_name)
            puts '-------------------------------'
            puts 'User already interacted: ' + user_name.to_s
            next
          end

          if (page.SS('video').count > 0)
            puts '-------------------------------'
            puts 'It was a video'
            next
          end

          if page.SS("a.#{COMMENTER_NAME}").map{ |comment| comment.evaluate('el => el.textContent') }.include?('fabi.rydel')
            puts '-------------------------------'
            puts 'I already commented'
            next
          end

          sleep sleep_interval
          likes = page.SS("a.#{LIKES}").present? ? page.SS("a.#{LIKES}").first.evaluate('el => el.textContent').gsub(' likes', '').gsub(' like', '').to_i : 0

          if likes > likes_thershold
            puts '-------------------------------'
            puts 'Too many likes already: ' + likes.to_s
            discarded_users.push(user_name)
            next
          end

          # Hover on user's name to see followers
          begin
            page.SS("div.#{USERNAME}").first.hover
            page.wait_for_selector('.lOXF2')
            followers = page.SS('span.lOXF2')[1].evaluate('el => el.textContent').gsub(',', '').to_i
          rescue
            followers = 1
          end

          sleep sleep_interval
          page.mouse.move(0,0)

          if followers > followers_thershold
            puts '-------------------------------'
            puts 'Too many followers already: ' + followers.to_s
            discarded_users.push(user_name)
            next
          end

          sleep sleep_interval
          page.SS("span.#{HEART}").first.click
          puts '+++++ LIKED +++++'
          liked_users.push(user_name)
          done = done + 1

          # Input comment
          sleep sleep_interval
          comment = if done % 3 == 0
            'Nice! 🙌🏼'
          elsif done % 3 == 1
            page.SS('div.coreSpriteRightChevron').present? ? 'Nice ones! 🙌🏼' : 'Nice! 🙌🏼'
          else
            page.SS('div.coreSpriteRightChevron').present? ? 'Great photos!' : 'Great photo!'
          end

          # Next photo if comments are disabled
          comment_input = page.SS("textarea.#{COMMENT_INPUT}").first
          next if comment_input.blank?

          comment_input.click
          sleep sleep_interval
          page.keyboard.type_text(comment)
          sleep sleep_interval
          page.SS("button.#{POST_BUTTON}").last.click
          puts '+++++ COMMENTED +++++'
        rescue
          page.screenshot(path: "error.png")
        end
      end
    end
  end
end