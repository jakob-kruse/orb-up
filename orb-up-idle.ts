import { mkdirSync, readFileSync, renameSync, rmSync, writeFileSync } from 'node:fs'
import { dirname } from 'node:path'
import type { PluginAPI } from '@ampcode/plugin'

export const description = 'Lets orb-up defer Amp updates while a runner is working'

export default function (amp: PluginAPI) {
	const stateFile = process.env.ORB_UP_RUNNER_STATE_FILE
	if (!stateFile) return

	const activeTurns = new Set<string>()
	const temporaryFile = `${stateFile}.${process.pid}.tmp`

	const writeState = () => {
		try {
			mkdirSync(dirname(stateFile), { recursive: true })
			const state = activeTurns.size === 0 ? 'idle' : 'busy'
			writeFileSync(temporaryFile, `${state} ${process.pid}\n`)
			renameSync(temporaryFile, stateFile)
		} catch (error) {
			try {
				rmSync(stateFile, { force: true })
				rmSync(temporaryFile, { force: true })
			} catch {
				// The updater treats a missing state file as unknown and safely defers.
			}
			amp.logger.log('Could not write orb-up runner state', error)
		}
	}

	writeState()

	amp.on('agent.start', (event) => {
		activeTurns.add(String(event.id))
		writeState()
		return {}
	})

	amp.on('agent.end', (event) => {
		activeTurns.delete(String(event.id))
		writeState()
	})

	amp.onDispose(() => {
		try {
			if (readFileSync(stateFile, 'utf8').trim().endsWith(` ${process.pid}`)) {
				rmSync(stateFile, { force: true })
			}
		} catch {
			// The state file may already have been removed by orb-up.
		}
		rmSync(temporaryFile, { force: true })
	})
}
