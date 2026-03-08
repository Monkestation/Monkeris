import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Flex,
  LabeledList,
  Section,
  Stack,
} from 'tgui-core/components';

import factionCEVCommand from '../assets/50px-Command.png';
import factionNeotheology from '../assets/54px-NeoTheology.png';
import factionCEVCivilians from '../assets/54px-Ship.png';
import factionGuild from '../assets/64px-Guild.png';
import factionIronhammer from '../assets/64px-Ironhammer.png';
import factionMoebius from '../assets/64px-Moebius.png';
import factionTechnomancers from '../assets/64px-Technomancers.png';
import { Window } from '../layouts';

type LateJoinData = {
  playerName: string;
  roundDuration: string;
  isEvacuating: boolean;
  isEvacuated: boolean;
  departments: Department[];
};

type Department = {
  name: string;
  jobs: Job[];
};

type Job = {
  title: string;
  currentPositions: number;
  totalPositions: number; // -1 = unlimited
  activePlayers: number;
  expRequired: number;
  expType: string;
  department: string;
  available: boolean;
  description: string;
  supervisors: string;
};

// Department logos
const DEPARTMENT_LOGOS: Record<string, string> = {
  'Ironhammer Mercenary Company': factionIronhammer,
  'Moebius Labs: Medical Division': factionMoebius,
  'Moebius Labs: Research Division': factionMoebius,
  'Asters Merchant Guild': factionGuild,
  'Church of NeoTheology': factionNeotheology,
  'CEV Eris Command': factionCEVCommand,
  'Technomancer League': factionTechnomancers,
  'CEV Eris Civilian': factionCEVCivilians,
};

// Department color scheme - backgrounds and accents
const DEPARTMENT_COLORS: Record<
  string,
  { bg: string; accent: string; button: string }
> = {
  'CEV Eris Command': {
    bg: 'rgba(74, 144, 226, 0.25)',
    accent: 'rgba(74, 144, 226, 0.8)',
    button: 'rgba(74, 144, 226, 0.15)',
  },
  'Ironhammer Mercenary Company': {
    bg: 'rgba(231, 76, 60, 0.25)',
    accent: 'rgba(231, 76, 60, 0.8)',
    button: 'rgba(231, 76, 60, 0.15)',
  },
  'Technomancer League': {
    bg: 'rgba(243, 156, 18, 0.25)',
    accent: 'rgba(243, 156, 18, 0.8)',
    button: 'rgba(243, 156, 18, 0.15)',
  },
  'Moebius Labs: Medical Division': {
    bg: 'rgba(100, 200, 255, 0.25)',
    accent: 'rgba(100, 200, 255, 0.8)',
    button: 'rgba(100, 200, 255, 0.15)',
  },
  'Moebius Labs: Research Division': {
    bg: 'rgba(155, 89, 182, 0.25)',
    accent: 'rgba(155, 89, 182, 0.8)',
    button: 'rgba(155, 89, 182, 0.15)',
  },
  'Church of NeoTheology': {
    bg: 'rgba(241, 196, 15, 0.25)',
    accent: 'rgba(241, 196, 15, 0.8)',
    button: 'rgba(241, 196, 15, 0.15)',
  },
  'Asters Merchant Guild': {
    bg: 'rgba(39, 174, 96, 0.25)',
    accent: 'rgba(39, 174, 96, 0.8)',
    button: 'rgba(39, 174, 96, 0.15)',
  },
  'CEV Eris Civilian': {
    bg: 'rgba(149, 165, 166, 0.25)',
    accent: 'rgba(149, 165, 166, 0.8)',
    button: 'rgba(149, 165, 166, 0.15)',
  },
  Offship: {
    bg: 'rgba(139, 69, 19, 0.25)',
    accent: 'rgba(139, 69, 19, 0.8)',
    button: 'rgba(139, 69, 19, 0.15)',
  },
  Silicon: {
    bg: 'rgba(52, 152, 219, 0.25)',
    accent: 'rgba(52, 152, 219, 0.8)',
    button: 'rgba(52, 152, 219, 0.15)',
  },
};

// Split departments into columns for better layout
const splitIntoColumns = (items: Department[], columns: number) => {
  const result: Department[][] = Array.from({ length: columns }, () => []);
  items.forEach((item, index) => {
    result[index % columns].push(item);
  });
  return result;
};

export const LateJoin = (props: any) => {
  const { act, data } = useBackend<LateJoinData>();
  const {
    playerName,
    roundDuration,
    isEvacuating: evacuating,
    isEvacuated: evacuated,
    departments,
  } = data;

  // Convert DM numbers to proper booleans
  const isEvacuating = !!evacuating;
  const isEvacuated = !!evacuated;

  const columns = splitIntoColumns(departments || [], 3);

  return (
    <Window width={1100} height={700} title="Late Join">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title={`Welcome, ${playerName}`}>
              <LabeledList>
                <LabeledList.Item label="Round Duration">
                  {roundDuration || 'Unknown'}
                </LabeledList.Item>
                {isEvacuating && !isEvacuated && (
                  <LabeledList.Item label="Status">
                    <Box color="bad">The station is evacuating!</Box>
                  </LabeledList.Item>
                )}
                {isEvacuated && (
                  <LabeledList.Item label="Status">
                    <Box color="bad">The station has been evacuated!</Box>
                  </LabeledList.Item>
                )}
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Flex>
              {columns.map((column, columnIndex) => (
                <Flex.Item
                  key={columnIndex}
                  basis="33%"
                  grow={1}
                  style={{ padding: '0 0.5em' }}
                >
                  <Stack vertical>
                    {column.map((dept) => {
                      const deptColors = DEPARTMENT_COLORS[dept.name] || {
                        bg: 'rgba(149, 165, 166, 0.25)',
                        accent: 'rgba(149, 165, 166, 0.8)',
                        button: 'rgba(149, 165, 166, 0.15)',
                      };
                      return (
                        <Stack.Item key={dept.name} mb={1}>
                          <Box
                            style={{
                              backgroundColor: deptColors.bg,
                              borderRadius: '4px',
                              padding: '0.5em',
                            }}
                          >
                            <Flex
                              mb={1}
                              align="center"
                              style={{
                                borderBottom: `2px solid ${deptColors.accent}`,
                                paddingBottom: '4px',
                                minHeight: '40px',
                              }}
                            >
                              <Flex.Item
                                grow={1}
                                style={{
                                  fontWeight: 'bold',
                                  display: 'flex',
                                  alignItems: 'center',
                                }}
                              >
                                {dept.name}
                              </Flex.Item>
                              {DEPARTMENT_LOGOS[dept.name] ? (
                                <Flex.Item>
                                  <img
                                    src={DEPARTMENT_LOGOS[dept.name]}
                                    style={{
                                      width: '32px',
                                      height: '32px',
                                      objectFit: 'contain',
                                      opacity: 0.8,
                                    }}
                                    alt={dept.name}
                                  />
                                </Flex.Item>
                              ) : (
                                <Flex.Item style={{ width: '32px' }} />
                              )}
                            </Flex>
                            <Stack vertical>
                              {dept.jobs.map((job) => {
                                const isAvailable = job.available;
                                const tooltipText = !isAvailable
                                  ? 'Not available (check requirements, positions, or bans)'
                                  : `You answer to ${job.supervisors}`;

                                return (
                                  <Stack.Item key={job.title}>
                                    <Button
                                      fluid
                                      disabled={!isAvailable}
                                      content={`${job.title} (${job.currentPositions}${
                                        job.totalPositions > 0
                                          ? `/${job.totalPositions}`
                                          : ''
                                      }) - Active: ${job.activePlayers}`}
                                      tooltip={tooltipText}
                                      onClick={() =>
                                        act('select_job', { job: job.title })
                                      }
                                      style={{
                                        backgroundColor: isAvailable
                                          ? deptColors.button
                                          : 'rgba(100, 100, 100, 0.1)',
                                        borderBottom: `2px solid ${
                                          isAvailable
                                            ? deptColors.accent
                                            : 'rgba(100, 100, 100, 0.3)'
                                        }`,
                                        opacity: isAvailable ? 1 : 0.5,
                                      }}
                                    />
                                  </Stack.Item>
                                );
                              })}
                            </Stack>
                          </Box>
                        </Stack.Item>
                      );
                    })}
                  </Stack>
                </Flex.Item>
              ))}
            </Flex>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
