j = jasmine.getEnv()

plans =
  p14:
    max_parallelism: 1
    min_parallelism: 1
    price: 19
    concurrency: 1
    type: 'concurrency'
  p15:
    max_parallelism: 1
    min_parallelism: 1
    price: 49
    concurrency: 1
    type: 'concurrency'
  p16:
    max_parallelism: 8
    min_parallelism: 2
    price: 149
    concurrency: 1
    type: 'concurrency'

testBilling = (plan, c, p, e) ->
  @expect((new CI.inner.Billing()).calculateCost(plan, c, p)).toEqual e

j.describe "calculateCost", ->
  j.it "should be correct for log2", ->
    m = CI.math
    @expect(m.log2 2).toEqual 1
    @expect(m.log2 4).toEqual 2
    @expect(m.log2 8).toEqual 3
    @expect(m.log2 3).toEqual 1.5849625007211563

  j.it "should be the same as on the server", ->
    testBilling(plans.p14, 1, 1, 19)
    testBilling(plans.p15, 1, 1, 49)
    testBilling(plans.p16, 1, 2, 149)
    testBilling(plans.p14, 0, 0, 19)
    testBilling(plans.p15, 0, 0, 49)
    testBilling(plans.p16, 0, 0, 149)
    testBilling(plans.p14, 2, 1, 68)
    testBilling(plans.p15, 4, 1, 196)
    testBilling(plans.p16, 4, 1, 296)
    testBilling(plans.p16, 4, 2, 296)
    testBilling(plans.p16, 4, 4, 395)
    testBilling(plans.p16, 4, 8, 494)
    testBilling(plans.p16, 4, 5, 427)

j.describe "ansiToHtml", ->
  t = CI.terminal
  j.it "shouldn't screw up simple text", ->
    @expect(t.ansiToHtml "").toEqual ""
    @expect(t.ansiToHtml "foo").toEqual "<span class='brblue'>foo</span>"

  j.it "should work for the following simple escape sequences", ->
    @expect(t.ansiToHtml "\u001b[1mfoo\u001b[m").toEqual "<span class='brblue'>foo</span>"
    @expect(t.ansiToHtml "\u001b[3mfoo\u001b[m").toEqual "<span class='brblue italic'>foo</span>"
    @expect(t.ansiToHtml "\u001b[30mfoo\u001b[m").toEqual "<span class='white'>foo</span>"
    @expect(t.ansiToHtml "\u001b[31mfoo\u001b[m").toEqual "<span class='red'>foo</span>"
    @expect(t.ansiToHtml "\u001b[32mfoo\u001b[m").toEqual "<span class='green'>foo</span>"
    @expect(t.ansiToHtml "\u001b[33mfoo\u001b[m").toEqual "<span class='yellow'>foo</span>"
    @expect(t.ansiToHtml "\u001b[34mfoo\u001b[m").toEqual "<span class='blue'>foo</span>"
    @expect(t.ansiToHtml "\u001b[35mfoo\u001b[m").toEqual "<span class='magenta'>foo</span>"
    @expect(t.ansiToHtml "\u001b[36mfoo\u001b[m").toEqual "<span class='cyan'>foo</span>"
    @expect(t.ansiToHtml "\u001b[37mfoo\u001b[m").toEqual "<span class='white'>foo</span>"

  j.it "shouldn't leave an open span even when the escape isn't reset", ->
    @expect(t.ansiToHtml "\u001b[32mfoo").toEqual "<span class='green'>foo</span>"

  j.it "should cope with leading text", ->
    @expect(t.ansiToHtml "foo\u001b[32mbar").toEqual "<span class='brblue'>foo</span><span class='green'>bar</span>"

  j.it "should cope with trailing text, and correctly clear styles", ->
    @expect(t.ansiToHtml "\u001b[32mfoo\u001b[mbar").toEqual "<span class='green'>foo</span><span class='brblue'>bar</span>"
    @expect(t.ansiToHtml "\u001b[32mfoo\u001b[0mbar").toEqual "<span class='green'>foo</span><span class='brblue'>bar</span>"

  j.it "should allow multiple escapes in sequence", ->
    @expect(t.ansiToHtml "\u001b[1;3;32mfoo").toEqual "<span class='brgreen italic'>foo</span>"

  j.it "should allow independent changes to styles", ->
    @expect(t.ansiToHtml "\u001b[1;3;32mfoo\u001b[22mbar\u001b[23mbaz\u001b[39mbarney").toEqual "<span class='brgreen italic'>foo</span><span class='green italic'>bar</span><span class='green'>baz</span><span class='brblue'>barney</span>"

  j.it "should strip escapes it doesn't understand", ->
    # only 'm' escapes are known currently
    @expect(t.ansiToHtml "\u001b[1Mfoo").toEqual "<span class='brblue'>foo</span>"
    # no blinking
    @expect(t.ansiToHtml "\u001b[5mfoo").toEqual "<span class='brblue'>foo</span>"

  j.it "should 'animate' carriage returns", ->
    @expect(t.ansiToHtml "foo\nfoo\r").toEqual "<span class='brblue'>foo\n</span><span class='brblue'>foo\r</span>"
    @expect(t.ansiToHtml "foo\nfoo\rbar\n").toEqual "<span class='brblue'>foo\n</span><span class='brblue'>bar\n</span>"

  j.it "should not throw away \r\n ended lines", ->
    @expect(t.ansiToHtml "rn\r\nend").toEqual "<span class='brblue'>rn\r\n</span><span class='brblue'>end</span>"

  j.it "shouldn't short-circuit because of empty lines", ->
    @expect(t.ansiToHtml "first\n\nsecond\n").toEqual "<span class='brblue'>first\n\n</span><span class='brblue'>second\n</span>"

  j.it "shouldn't blow up if the first line is empty", ->
    @expect(t.ansiToHtml "\r\nfirst\n").toEqual "<span class='brblue'>\r\n</span><span class='brblue'>first\n</span>"

j.describe "githubAuthURL", ->
  j.it "should be the expect values", ->
    @expect(CI.github.authUrl()).toEqual "https://github.com/login/oauth/authorize?client_id=586bf699b48f69a09d8c&redirect_uri=http%3A%2F%2Fcirclehost%3A8080%2Fauth%2Fgithub%3Freturn-to%3D%252Ftests%252Finner&scope=user%2Crepo"
    @expect(CI.github.authUrl([])).toEqual "https://github.com/login/oauth/authorize?client_id=586bf699b48f69a09d8c&redirect_uri=http%3A%2F%2Fcirclehost%3A8080%2Fauth%2Fgithub%3Freturn-to%3D%252Ftests%252Finner&scope="


j.describe "plans page", ->
  j.describe "invoice list", ->
    it "should work", ->
      i = new CI.inner.Invoice
        amount_due: 14900
        currency: "usd"
        date:         1358984466
        paid: true
        period_start: 1358831737 # numbers chosen to be close to the date boundary
        period_end:   1358984466
      @expect(i.time_period()).toEqual "2013/01/22 - 2013/01/23"
      @expect(i.invoice_date()).toEqual "2013/01/23"

j.describe "CI.stringHelpers.trimMiddle", ->
  j.it "should not make strings longer", ->
    @expect(CI.stringHelpers.trimMiddle("four", 2)).toEqual "four"
  j.it "should make long strings short", ->
    twenty = "01234567890123456789"
    @expect(CI.stringHelpers.trimMiddle(twenty, 10).length).toEqual 10
    @expect(CI.stringHelpers.trimMiddle(twenty, 10)).toEqual "012...6789"

j.describe "time works", ->
  j.it "over 1 minute is correct", ->
    @expect(CI.time.as_duration(1000)).toEqual "1s"
    @expect(CI.time.as_duration(100000)).toEqual "1m 40s"
    @expect(CI.time.as_duration(1000000)).toEqual "16m 40s"


j.describe "headings get link anchors correctly", ->
  d = VM.docs
  console.log d
  j.it "should work for existing ids", ->
    h = "<h2 id='asd'>Some title</h2>"
    expected = '<h2 id="asd"><a href="#asd">Some title</a></h2>'
    @expect(d.addLinkTarget(h)[0].outerHTML).toEqual expected

  j.it "should work when there are no ids", ->
    h = "<h2>Some title</h2>"
    expected = '<h2 id="some-title"><a href="#some-title">Some title</a></h2>'
    @expect(d.addLinkTarget(h)[0].outerHTML).toEqual expected

  j.it "should work correctly with apostrophies", ->
    h = "<h2>Someone's title</h2>"
    expected = '<h2 id="someones-title"><a href="#someones-title">Someone\'s title</a></h2>'
    @expect(d.addLinkTarget(h)[0].outerHTML).toEqual expected

j.describe "setting project parallelism works", ->
  VM.current_user = ko.observable(new CI.inner.User({login: 'test-user'}))

  j.it "should handle trials", ->
    project = new CI.inner.Project
      parallel: 2
    project.billing.loadPlanData
      containers: 6
      plan:
        max_parallelism: 6
        price: null
        type: "trial"

    @expect(project.paid_speed()).toEqual 6
    @expect(project.plan_max_speed()).toEqual 6
    @expect(project.payor_login()).toBe(null)

    # Allow them to select 5x
    @expect(project.parallel_label_style(5).disabled()).not.toBe(true)

    # Don't allow them to select 8x
    @expect(project.parallel_label_style(8).disabled()).toEqual(true)

    @expect(project.show_parallel_upgrade_plan_p()).not.toBe(true)
    @expect(project.show_parallel_upgrade_speed_p()).not.toBe(true)

  j.it "should handle concurrency-type plans", ->
    project = new CI.inner.Project
      parallel: 2
    project.billing.loadPlanData
      plan:
        max_parallelism: 3
        price: null
        type: "concurrency"
      payor:
        login: 'daniel'
      concurrency: 5
      parallelism: 2

    @expect(project.paid_speed()).toEqual 2
    @expect(project.plan_max_speed()).toEqual 3
    @expect(project.payor_login()).toBe('daniel')
    @expect(project.parallel_label_style(2).disabled()).toBe(false)
    @expect(project.parallel_label_style(3).disabled()).toBe(true)
    @expect(project.parallel_label_style(4).disabled()).toBe(true)
    @expect(project.current_user_is_payor_p()).not.toBe(true)

    # Don't tell them to upgrade for things they can click
    project.focused_parallel(2)
    @expect(project.show_parallel_upgrade_plan_p()).not.toBe(true)
    @expect(project.show_parallel_upgrade_speed_p()).not.toBe(true)

    # Don't tell them to upgrade their plan if it supports higher speed
    project.focused_parallel(3)
    @expect(project.show_parallel_upgrade_plan_p()).not.toBe(true)
    @expect(project.show_parallel_upgrade_speed_p()).toBe(true)

    # Don't tell them to upgrade their speed if their plan doesn't supports it
    project.focused_parallel(4)
    @expect(project.show_parallel_upgrade_plan_p()).toBe(true)
    @expect(project.show_parallel_upgrade_speed_p()).not.toBe(true)

  j.it "should handle container-type plans", ->
    project = new CI.inner.Project
      parallel: 2
    project.billing.loadPlanData
      plan:
        max_parallelism: 3
        price: null
        type: "containers"
      payor:
        login: 'daniel'
      concurrency: 5
      parallelism: 2
      containers: 2

    @expect(project.paid_speed()).toEqual 2
    @expect(project.plan_max_speed()).toEqual 3
    @expect(project.payor_login()).toBe('daniel')
    @expect(project.parallel_label_style(2).disabled()).not.toBe(true)
    @expect(project.parallel_label_style(3).disabled()).toBe(true)
    @expect(project.parallel_label_style(4).disabled()).toBe(true)

    # Don't tell them to upgrade for things they can click
    project.focused_parallel(2)
    @expect(project.show_parallel_upgrade_plan_p()).not.toBe(true)
    @expect(project.show_parallel_upgrade_speed_p()).not.toBe(true)

    # Don't tell them to upgrade their plan if it supports higher speed
    project.focused_parallel(3)
    @expect(project.show_parallel_upgrade_plan_p()).not.toBe(true)
    @expect(project.show_parallel_upgrade_speed_p()).toBe(true)

    # Don't tell them to upgrade their speed if their plan doesn't supports it
    project.focused_parallel(4)
    @expect(project.show_parallel_upgrade_plan_p()).toBe(true)
    @expect(project.show_parallel_upgrade_speed_p()).not.toBe(true)

    project.billing.containers(5)
    project.focused_parallel(2)
    @expect(project.show_parallel_upgrade_plan_p()).not.toBe(true)
    @expect(project.show_parallel_upgrade_speed_p()).not.toBe(true)

    project.focused_parallel(3)
    @expect(project.show_parallel_upgrade_plan_p()).not.toBe(true)
    @expect(project.show_parallel_upgrade_speed_p()).not.toBe(true)

    project.focused_parallel(4)
    @expect(project.show_parallel_upgrade_plan_p()).toBe(true)
    @expect(project.show_parallel_upgrade_speed_p()).not.toBe(true)
