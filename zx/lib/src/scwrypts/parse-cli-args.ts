export type CLIArgs = string | string[] | undefined;

export const parseCLIArgs = (args: CLIArgs): string[] => {
  switch (typeof args) {
    case 'undefined':
      return [];
    case 'string':
      return args.split(' ');
    default:
      return args;
  }
};
