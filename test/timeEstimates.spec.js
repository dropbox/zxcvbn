import TimeEstimates from '../src/TimeEstimates'

// TODO add tests
describe('timeEstimates', () => {
  const timeEstimates = new TimeEstimates()

  it('should be very weak', () => {
    const attackTimes = timeEstimates.estimateAttackTimes(10)
    expect(attackTimes).toEqual({
      crackTimesDisplay: {
        offline_fast_hashing_1e10_per_second: 'less than a second',
        offline_slow_hashing_1e4_per_second: 'less than a second',
        online_no_throttling_10_per_second: '1 second',
        online_throttling_100_per_hour: '6 minutes',
      },
      crackTimesSeconds: {
        offline_fast_hashing_1e10_per_second: 1e-9,
        offline_slow_hashing_1e4_per_second: 0.001,
        online_no_throttling_10_per_second: 1,
        online_throttling_100_per_hour: 360,
      },
      score: 0,
    })
  })

  it('should be weak', () => {
    const attackTimes = timeEstimates.estimateAttackTimes(100000)
    expect(attackTimes).toEqual({
      crackTimesDisplay: {
        offline_fast_hashing_1e10_per_second: 'less than a second',
        offline_slow_hashing_1e4_per_second: '10 seconds',
        online_no_throttling_10_per_second: '3 hours',
        online_throttling_100_per_hour: '1 month',
      },
      crackTimesSeconds: {
        offline_fast_hashing_1e10_per_second: 0.00001,
        offline_slow_hashing_1e4_per_second: 10,
        online_no_throttling_10_per_second: 10000,
        online_throttling_100_per_hour: 3600000,
      },
      score: 1,
    })
  })

  it('should be good', () => {
    const attackTimes = timeEstimates.estimateAttackTimes(10000000)
    expect(attackTimes).toEqual({
      crackTimesDisplay: {
        offline_fast_hashing_1e10_per_second: 'less than a second',
        offline_slow_hashing_1e4_per_second: '17 minutes',
        online_no_throttling_10_per_second: '12 days',
        online_throttling_100_per_hour: '11 years',
      },
      crackTimesSeconds: {
        offline_fast_hashing_1e10_per_second: 0.001,
        offline_slow_hashing_1e4_per_second: 1000,
        online_no_throttling_10_per_second: 1000000,
        online_throttling_100_per_hour: 360000000,
      },
      score: 2,
    })
  })
  it('should be very good', () => {
    const attackTimes = timeEstimates.estimateAttackTimes(1000000000)
    expect(attackTimes).toEqual({
      crackTimesDisplay: {
        offline_fast_hashing_1e10_per_second: 'less than a second',
        offline_slow_hashing_1e4_per_second: '1 day',
        online_no_throttling_10_per_second: '3 years',
        online_throttling_100_per_hour: 'centuries',
      },
      crackTimesSeconds: {
        offline_fast_hashing_1e10_per_second: 0.1,
        offline_slow_hashing_1e4_per_second: 100000,
        online_no_throttling_10_per_second: 100000000,
        online_throttling_100_per_hour: 36000000000,
      },
      score: 3,
    })
  })

  it('should be excellent', () => {
    const attackTimes = timeEstimates.estimateAttackTimes(100000000000)
    expect(attackTimes).toEqual({
      crackTimesDisplay: {
        offline_fast_hashing_1e10_per_second: '10 seconds',
        offline_slow_hashing_1e4_per_second: '4 months',
        online_no_throttling_10_per_second: 'centuries',
        online_throttling_100_per_hour: 'centuries',
      },
      crackTimesSeconds: {
        offline_fast_hashing_1e10_per_second: 10,
        offline_slow_hashing_1e4_per_second: 10000000,
        online_no_throttling_10_per_second: 10000000000,
        online_throttling_100_per_hour: 3600000000000,
      },
      score: 4,
    })
  })
})
