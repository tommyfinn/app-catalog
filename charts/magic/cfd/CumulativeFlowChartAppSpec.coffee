Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.apps.charts.magic.cfd.CumulativeFlowChartApp'
]

describe 'Rally.apps.charts.magic.cfd.CumulativeFlowChartApp', ->

  beforeEach ->
    @lumenize = Rally.data.lookback.Lumenize

    snapshotsCSV = [
      ["ObjectID", "_ValidFrom", "_ValidTo", "ScheduleState", "PlanEstimate", "TaskRemainingTotal", "TaskEstimateTotal"],
      [1, "2011-01-02T13:00:00.000Z", "2011-01-02T15:10:00.000Z", "Ready to pull", 5             , 15                  , 15],
      [1, "2011-01-02T15:10:00.000Z", "2011-01-03T15:00:00.000Z", "In progress"  , 5             , 20                  , 15],
      [2, "2011-01-02T15:00:00.000Z", "2011-01-03T15:00:00.000Z", "Ready to pull", 3             , 5                   , 5],
      [3, "2011-01-02T15:00:00.000Z", "2011-01-03T15:00:00.000Z", "Ready to pull", 5             , 12                  , 12],
      [2, "2011-01-03T15:00:00.000Z", "2011-01-04T15:00:00.000Z", "In progress"  , 3             , 5                   , 5],
      [3, "2011-01-03T15:00:00.000Z", "2011-01-04T15:00:00.000Z", "Ready to pull", 5             , 12                  , 12],
      [4, "2011-01-03T15:00:00.000Z", "2011-01-04T15:00:00.000Z", "Ready to pull", 5             , 15                  , 15],
      [1, "2011-01-03T15:10:00.000Z", "2011-01-04T15:00:00.000Z", "In progress"  , 5             , 12                  , 15],
      [1, "2011-01-04T15:00:00.000Z", "2011-01-06T15:00:00.000Z", "Accepted"     , 5             , 0                   , 15],
      [2, "2011-01-04T15:00:00.000Z", "2011-01-06T15:00:00.000Z", "In test"      , 3             , 1                   , 5],
      [3, "2011-01-04T15:00:00.000Z", "2011-01-05T15:00:00.000Z", "In progress"  , 5             , 10                  , 12],
      [4, "2011-01-04T15:00:00.000Z", "2011-01-06T15:00:00.000Z", "Ready to pull", 5             , 15                  , 15],
      [5, "2011-01-04T15:00:00.000Z", "2011-01-06T15:00:00.000Z", "Ready to pull", 2             , 4                   , 4],
      [3, "2011-01-05T15:00:00.000Z", "2011-01-07T15:00:00.000Z", "In test"      , 5             , 5                   , 12],
      [1, "2011-01-06T15:00:00.000Z", "2011-01-07T15:00:00.000Z", "Released"     , 5             , 0                   , 15],
      [2, "2011-01-06T15:00:00.000Z", "2011-01-07T15:00:00.000Z", "Accepted"     , 3             , 0                   , 5],
      [4, "2011-01-06T15:00:00.000Z", "2011-01-07T15:00:00.000Z", "In progress"  , 5             , 7                   , 15],
      [5, "2011-01-06T15:00:00.000Z", "2011-01-07T15:00:00.000Z", "Ready to pull", 2             , 4                   , 4],
      [1, "2011-01-07T15:00:00.000Z", "9999-01-01T00:00:00.000Z", "Released"     , 5            , 0                    , 15],
      [2, "2011-01-07T15:00:00.000Z", "9999-01-01T00:00:00.000Z", "Released"     , 3            , 0                    , 5],
      [3, "2011-01-07T15:00:00.000Z", "9999-01-01T00:00:00.000Z", "Accepted"     , 5            , 0                    , 12],
      [4, "2011-01-07T15:00:00.000Z", "9999-01-01T00:00:00.000Z", "In test"      , 5            , 3                    , 15]  # Note: ObjectID 5 deleted
    ]

    @ajax.whenQueryingLookbackApi().respondWith(@lumenize.csvStyleArray_To_ArrayOfMaps(snapshotsCSV))

    @project = Rally.environment.getContext().getProject()

  afterEach ->
    @app?.destroy()
    Rally.test.destroyComponentsOfQuery 'cumulativeflowchartapp'

  it 'has the correct default settings', ->
    @createApp().then =>
      expect(@app).not.toBeNull()
      expect(@app.getSetting('stateFieldName')).toBe 'ScheduleState'
      expect(@app.getSetting('stateFieldValues')).toBe 'Idea,Defined,In-Progress,Completed,Accepted,Released'

  it 'has key chartAppConfig elements in the right places', ->
    @createApp().then =>
      config = @app._getChartAppConfig()
      expect(config).not.toBeNull()
      expect(config.storeConfig).not.toBeNull() # tested elsewhere
      expect(config.calculatorType).toBe 'ProjectCFDCalculator'
      expect(config.calculatorConfig).not.toBeNull() # tested elsewhere
      expect(config.listeners.chartRendered).toBe @app._publishComponentReady
      expect(config.chartConfig.title.text).toBe @project.Name + ' Cumulative Flow Diagram'

  it 'has correct chartStore', ->
    @createApp().then =>
      storeConfig = @app._getChartStoreConfig()
      expect(storeConfig).not.toBeNull()
      expect(storeConfig.find.Project).toBe @project.ObjectID

  it 'has correct chartCalculatorConfig', ->
    settings = {
      stateFieldName: 'testfield',
      stateFieldValues: 'val1,val2,val3'
    }
    @createApp(settings).then =>
      calcConfig = @app._getChartCalculatorConfig()
      expect(calcConfig.stateFieldName).toBe settings.stateFieldName
      expect(calcConfig.stateFieldValues).toBe settings.stateFieldValues

  helpers
    getContext: (initialValues) ->
      globalContext = Rally.environment.getContext()

      Ext.create 'Rally.app.Context',
        initialValues: Ext.merge(
          project: globalContext.getProject()
          workspace: globalContext.getWorkspace()
          user: globalContext.getUser()
          subscription: globalContext.getSubscription()
        , initialValues)

    createApp: (settings = {}) ->
      @app = Ext.create('Rally.apps.charts.magic.cfd.CumulativeFlowChartApp',
        context: @getContext(),
        settings: settings,
        renderTo: 'testDiv'
      )

      @waitForComponentReady @app
