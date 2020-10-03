import TimeEstimates from '../src/TimeEstimates'
import Options from '~/Options'

Options.setOptions()

// TODO add tests
describe('timeEstimates', () => {
  const timeEstimates = new TimeEstimates()

  it('should be very weak', () => {
    const attackTimes = timeEstimates.estimateAttackTimes(10)
    expect(attackTimes).toEqual({
      crackTimesDisplay: {
        offlineFastHashing1e10PerSecond: 'less than a second',
        offlineSlowHashing1e4PerSecond: 'less than a second',
        onlineThrottling10PerSecond: '1 second',
        onlineThrottling100PerHour: '6 minutes',
      },
      crackTimesSeconds: {
        offlineFastHashing1e10PerSecond: 1e-9,
        offlineSlowHashing1e4PerSecond: 0.001,
        onlineThrottling10PerSecond: 1,
        onlineThrottling100PerHour: 360,
      },
      score: 0,
    })
  })

  it('should be weak', () => {
    const attackTimes = timeEstimates.estimateAttackTimes(100000)
    expect(attackTimes).toEqual({
      crackTimesDisplay: {
        offlineFastHashing1e10PerSecond: 'less than a second',
        offlineSlowHashing1e4PerSecond: '10 seconds',
        onlineThrottling10PerSecond: '3 hours',
        onlineThrottling100PerHour: '1 month',
      },
      crackTimesSeconds: {
        offlineFastHashing1e10PerSecond: 0.00001,
        offlineSlowHashing1e4PerSecond: 10,
        onlineThrottling10PerSecond: 10000,
        onlineThrottling100PerHour: 3600000,
      },
      score: 1,
    })
  })

  it('should be good', () => {
    const attackTimes = timeEstimates.estimateAttackTimes(10000000)
    expect(attackTimes).toEqual({
      crackTimesDisplay: {
        offlineFastHashing1e10PerSecond: 'less than a second',
        offlineSlowHashing1e4PerSecond: '17 minutes',
        onlineThrottling10PerSecond: '12 days',
        onlineThrottling100PerHour: '11 years',
      },
      crackTimesSeconds: {
        offlineFastHashing1e10PerSecond: 0.001,
        offlineSlowHashing1e4PerSecond: 1000,
        onlineThrottling10PerSecond: 1000000,
        onlineThrottling100PerHour: 360000000,
      },
      score: 2,
    })
  })
  it('should be very good', () => {
    const attackTimes = timeEstimates.estimateAttackTimes(1000000000)
    expect(attackTimes).toEqual({
      crackTimesDisplay: {
        offlineFastHashing1e10PerSecond: 'less than a second',
        offlineSlowHashing1e4PerSecond: '1 day',
        onlineThrottling10PerSecond: '3 years',
        onlineThrottling100PerHour: 'centuries',
      },
      crackTimesSeconds: {
        offlineFastHashing1e10PerSecond: 0.1,
        offlineSlowHashing1e4PerSecond: 100000,
        onlineThrottling10PerSecond: 100000000,
        onlineThrottling100PerHour: 36000000000,
      },
      score: 3,
    })
  })

  it('should be excellent', () => {
    const attackTimes = timeEstimates.estimateAttackTimes(100000000000)
    expect(attackTimes).toEqual({
      crackTimesDisplay: {
        offlineFastHashing1e10PerSecond: '10 seconds',
        offlineSlowHashing1e4PerSecond: '4 months',
        onlineThrottling10PerSecond: 'centuries',
        onlineThrottling100PerHour: 'centuries',
      },
      crackTimesSeconds: {
        offlineFastHashing1e10PerSecond: 10,
        offlineSlowHashing1e4PerSecond: 10000000,
        onlineThrottling10PerSecond: 10000000000,
        onlineThrottling100PerHour: 3600000000000,
      },
      score: 4,
    })
  })
})
