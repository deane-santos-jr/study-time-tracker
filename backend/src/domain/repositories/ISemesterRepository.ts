import { Semester } from '../entities/Semester';

export interface ISemesterRepository {
  create(semester: Semester): Promise<Semester>;
  findById(id: string): Promise<Semester | null>;
  findByUserId(userId: string): Promise<Semester[]>;
  findActiveByUserId(userId: string): Promise<Semester | null>;
  update(semester: Semester): Promise<Semester>;
  delete(id: string): Promise<void>;
}
