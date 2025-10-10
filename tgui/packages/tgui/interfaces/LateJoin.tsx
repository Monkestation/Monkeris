import { Box, Button, Section, Stack } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface LateJoinData {
  name: string;
  roundDuration: string | number;
  evacuated: BooleanLike;
  evacuating: BooleanLike;
  emergencyEvac: BooleanLike;
  jobs: Array<{
    title: string;
    positions: number;
    active: number;
  }>;
}

export const LateJoin = () => {
  const { act, data } = useBackend<LateJoinData>();
  const {
    name,
    roundDuration,
    evacuated,
    evacuating,
    emergencyEvac,
    jobs = [],
  } = data;

  return (
    <Window width={400} height={640}>
      <Window.Content scrollable>
        <Section>
          <Box mb={1}>Welcome, {name}.</Box>
          <Box mb={2}>Round Duration: {roundDuration}</Box>

          {!!evacuated && (
            <Box color="red" mb={2}>
              The vessel has been evacuated.
            </Box>
          )}
          {!!evacuating && (
            <Box color="red" mb={2}>
              {emergencyEvac
                ? 'The vessel is currently undergoing evacuation procedures.'
                : 'The vessel is currently undergoing crew transfer procedures.'}
            </Box>
          )}
        </Section>

        <Section title="Available Positions">
          <Stack vertical>
            {jobs.map((job) => (
              <Stack.Item key={job.title}>
                <Button
                  fluid
                  onClick={() => act('select_job', { title: job.title })}
                >
                  <Box
                    inline
                    width="100%"
                    textAlign="left"
                    style={{
                      display: 'grid',
                      gridTemplateColumns: '2fr 1fr 1fr',
                    }}
                  >
                    <Box>{job.title}</Box>
                    <Box textAlign="center">({job.positions})</Box>
                    <Box textAlign="right">Active: {job.active}</Box>
                  </Box>
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
