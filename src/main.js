import Matching from './Matching'
import scoring from './scoring'
import TimeEstimates from './TimeEstimates'
import Feedback from './Feedback'
import Options, { defaultOptions } from './Options'

const time = () => new Date().getTime()

export default (password, userInputs = [], options) => {
  const usedOptions = {
    ...defaultOptions,
    ...options,
  }
  Options.setOptions(usedOptions)
  const feedback = new Feedback()
  const matching = new Matching(usedOptions.matcher)
  const timeEstimates = new TimeEstimates()

  const start = time()
  const sanitizedInputs = []

  userInputs.forEach((input) => {
    const inputType = typeof input
    if (
      inputType === 'string' ||
      inputType === 'number' ||
      inputType === 'boolean'
    ) {
      sanitizedInputs.push(input.toString().toLowerCase())
    }
  })

  const matches = matching.match(password, {
    userInputs: sanitizedInputs,
  })
  const result = scoring.most_guessable_match_sequence(password, matches)
  result.calc_time = time() - start
  const attackTimes = timeEstimates.estimateAttackTimes(result.guesses)
  let val = ''
  Object.keys(attackTimes).forEach((prop) => {
    val = attackTimes[prop]
    result[prop] = val
  })
  result.feedback = feedback.getFeedback(result.score, result.sequence)
  return result
}
