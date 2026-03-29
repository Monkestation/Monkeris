import { Fragment, useState } from 'react';

import { useBackend } from 'tgui/backend';
import { Box, Divider, Section, Stack } from 'tgui-core/components';

import { Window } from '../layouts';

type ObjectiveGroup = {
  label: string;
  objectives: { text: string }[];
};

type IndividualObjective = {
  num: number;
  name: string;
  desc: string;
  limited_antag: boolean;
  show_la?: string;
};

type MemoryData = {
  name: string;
  memory: string;
  objective_groups: ObjectiveGroup[];
  individual_objectives: IndividualObjective[];
  la_explanation?: string;
};

/**
 * Wraps a copyable value with a placeholder so MemoryLines can replace it
 * with an interactive CopyToken component after parsing.
 */
const COPY_SENTINEL = '\x00COPY\x00';
const copyTokens: { value: string; color: string }[] = [];

const makeCopyToken = (value: string, color: string): string => {
  const idx = copyTokens.length;
  copyTokens.push({ value, color });
  return `${COPY_SENTINEL}${idx}${COPY_SENTINEL}`;
};

const CopyToken = ({
  value,
  color,
}: {
  value: string;
  color: string;
}) => {
  const [copied, setCopied] = useState(false);

  const handleClick = () => {
    navigator.clipboard?.writeText(value).catch(() => {
      const el = document.createElement('textarea');
      el.value = value;
      document.body.appendChild(el);
      el.select();
      document.execCommand('copy');
      document.body.removeChild(el);
    });
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <Box
      as="span"
      onClick={handleClick}
      style={{
        position: 'relative',
        cursor: 'pointer',
        color,
        fontWeight: 'bold',
        borderBottom: `1px dashed ${color}`,
        userSelect: 'none',
      }}
      title="Click to copy"
    >
      {value}
      {copied && (
        <Box
          as="span"
          style={{
            position: 'absolute',
            bottom: '120%',
            left: '50%',
            transform: 'translateX(-50%)',
            backgroundColor: '#2ecc71',
            color: '#111',
            fontSize: '0.8em',
            fontWeight: 'bold',
            padding: '2px 6px',
            borderRadius: '3px',
            whiteSpace: 'nowrap',
            pointerEvents: 'none',
          }}
        >
          ✓ copied
        </Box>
      )}
    </Box>
  );
};

/**
 * Highlights known sensitive fields and wraps copyable values with tokens.
 * Copyable: email addresses, passwords, uplink passcodes.
 * Code Phrase → green, Code Response → red.
 */
const styleMemory = (raw: string): string => {
  copyTokens.length = 0;
  return raw
    .replace(
      /([a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,})/g,
      (_, email) => `<span style='color:#6ab0de'>${makeCopyToken(email, '#6ab0de')}</span>`,
    )
    .replace(
      /((?:password|pin) is )([^\s<.,]+)/gi,
      (_, prefix, val) => `${prefix}${makeCopyToken(val, '#2ecc71')}`,
    )
    .replace(
      /(<[Bb]>(?:Your )?(?:department's )?account number is:<\/[Bb]> #?)(\d+)/gi,
      (_, prefix, val) => `${prefix}${makeCopyToken(val, '#f0c040')}`,
    )
    .replace(
      /(<[Bb]>(?:Your )?(?:department's )?account pin is:<\/[Bb]> )(\d+)/gi,
      (_, prefix, val) => `${prefix}${makeCopyToken(val, '#2ecc71')}`,
    )
    .replace(
      /(<[Bb]>Uplink passcode:<\/[Bb]> )([^<.(]+?)(?=\s*\()/g,
      (_, prefix, val) => `${prefix}${makeCopyToken(val.trim(), '#c678dd')}`,
    )
    .replace(
      /(<[Bb]>Radio Freq:<\/[Bb]> )([^<(]+?)(?=\s*\()/g,
      (_, prefix, val) => `${prefix}${makeCopyToken(val.trim(), '#c678dd')}`,
    )
    .replace(
      /(<[Bb]>Code Phrase<\/[Bb]>: )([^<\n]+)/g,
      (_, prefix, val) =>
        `${prefix}<span style='color:#2ecc71;font-weight:bold'>${val.trim()}</span>`,
    )
    .replace(
      /(<[Bb]>Code Response<\/[Bb]>: )([^<\n]+)/g,
      (_, prefix, val) =>
        `${prefix}<span style='color:#e74c3c;font-weight:bold'>${val.trim()}</span>`,
    );
};

/**
 * Splits a styled HTML string on <BR> tags and renders each line, replacing
 * COPY_SENTINEL tokens with interactive CopyToken components.
 */
const MemoryLines = ({ html }: { html: string }) => {
  const styled = styleMemory(html);
  const rawLines = styled.split(/<br\s*\/?>/i);

  // Collapse consecutive empty lines into a single gap marker
  type Line = { empty: true } | { empty: false; content: string };
  const lines: Line[] = [];
  for (const raw of rawLines) {
    const isEmpty = raw.trim().length === 0;
    if (isEmpty) {
      if (lines.length > 0 && !lines[lines.length - 1].empty) {
        lines.push({ empty: true });
      }
    } else {
      lines.push({ empty: false, content: raw });
    }
  }

  return (
    <>
      {lines.map((line, i) => {
        if (line.empty) {
          return <Box key={i} mb={2} />;
        }
        const parts = line.content.split(new RegExp(`${COPY_SENTINEL}(\\d+)${COPY_SENTINEL}`));
        return (
          <Box key={i} mb="2px">
            {parts.map((part, j) => {
              if (j % 2 === 1) {
                const token = copyTokens[Number(part)];
                return (
                  <Fragment key={j}>
                    <CopyToken value={token.value} color={token.color} />
                  </Fragment>
                );
              }
              return (
                <Box
                  key={j}
                  as="span"
                  dangerouslySetInnerHTML={{ __html: part }}
                />
              );
            })}
          </Box>
        );
      })}
    </>
  );
};

export const Memory = () => {
  const { data } = useBackend<MemoryData>();
  const {
    name,
    memory,
    objective_groups,
    individual_objectives,
    la_explanation,
  } = data;

  const hasObjectives =
    (objective_groups && objective_groups.length > 0) ||
    (individual_objectives && individual_objectives.length > 0);

  return (
    <Window width={420} height={500} title="Memory">
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section title={`${name}'s Memory`}>
              {memory ? (
                <MemoryLines html={memory} />
              ) : (
                <Box color="label">No notes recorded.</Box>
              )}
            </Section>
          </Stack.Item>
          {hasObjectives && (
            <Stack.Item>
              {objective_groups &&
                objective_groups.map((group, i) => (
                  <Section key={i} title={group.label}>
                    <Stack vertical>
                      {group.objectives.map((obj, j) => (
                        <Stack.Item key={j}>
                          <Box>
                            <Box as="span" bold mr={1}>
                              Objective {j + 1}:
                            </Box>
                            <Box
                              as="span"
                              dangerouslySetInnerHTML={{ __html: obj.text }}
                            />
                          </Box>
                        </Stack.Item>
                      ))}
                    </Stack>
                  </Section>
                ))}
              {individual_objectives && individual_objectives.length > 0 && (
                <Section title="Your Individual Objectives">
                  <Stack vertical>
                    {individual_objectives.map((obj) => (
                      <Stack.Item key={obj.num}>
                        <Box>
                          <Box as="span" bold mr={1}>
                            #{obj.num} {obj.name}
                            {obj.limited_antag && obj.show_la && (
                              <Box
                                as="span"
                                ml={1}
                                dangerouslySetInnerHTML={{
                                  __html: obj.show_la,
                                }}
                              />
                            )}
                            :
                          </Box>
                          <Box
                            as="span"
                            dangerouslySetInnerHTML={{ __html: obj.desc }}
                          />
                        </Box>
                      </Stack.Item>
                    ))}
                  </Stack>
                  {la_explanation && (
                    <>
                      <Divider />
                      <Box
                        mt={1}
                        fontSize="0.85em"
                        dangerouslySetInnerHTML={{ __html: la_explanation }}
                      />
                    </>
                  )}
                </Section>
              )}
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
