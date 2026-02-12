import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Button, Section, Stack, Tabs } from 'tgui-core/components';

import type { LibraryConsoleData } from '../types';

export function Print(props) {
  const { act, data } = useBackend<LibraryConsoleData>();
  const { posters } = data;

  const [selectedPoster, setSelectedPoster] = useState(posters[0]);

  const noPosters = posters.length === 0;

  return (
    <Stack vertical fill>
      <Stack.Item grow>
        <Stack fill>
          <Stack.Item width="50%">
            <Section fill scrollable>
              <Tabs vertical>
                {posters.map((poster) => {
                  const selected = selectedPoster === poster;

                  return (
                    <Tabs.Tab
                      className="candystripe"
                      selected={selected}
                      color={selected && 'good'}
                      key={poster}
                      onClick={() => setSelectedPoster(poster)}
                    >
                      {poster}
                    </Tabs.Tab>
                  );
                })}
              </Tabs>
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack justify="space-between">
          <Stack.Item grow>
            <Button
              fluid
              icon="scroll"
              fontSize="30px"
              lineHeight={2}
              textAlign="center"
              disabled={noPosters}
              tooltip={noPosters ? 'No posters available!' : undefined}
              onClick={() =>
                act('print_poster', {
                  poster_name: selectedPoster,
                })
              }
            >
              Poster
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
}
